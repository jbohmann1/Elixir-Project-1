defmodule RTTaskBoard.Store do
  use GenServer
  alias RTTaskBoard.{Task, JobQueue}

  @name __MODULE__
  @default_file "tasks.json"

  @log_table :rt_task_log
  @log_limit 200

  # ——— Public API ———
  def start_link(_args), do: GenServer.start_link(__MODULE__, :ok, name: @name)
  def add(title, desc \\ ""), do: GenServer.call(@name, {:add, title, desc})
  def list, do: GenServer.call(@name, :list)
  def done(id), do: GenServer.call(@name, {:done, id})
  def save(path \\ @default_file), do: GenServer.call(@name, {:save, path})
  def load(path \\ @default_file), do: GenServer.call(@name, {:load, path})

  # Fast ETS read
  def recent(n \\ 20) do
    case :ets.whereis(@log_table) do
      :undefined -> []
      tid ->
        last = :ets.last(tid)
        take_prev(tid, last, n, []) |> Enum.reverse()
    end
  end

  defp take_prev(_tid, :"$end_of_table", _n, acc), do: acc
  defp take_prev(_tid, _key, 0, acc), do: acc
  defp take_prev(tid, key, n, acc) do
    [{^key, event}] = :ets.lookup(tid, key)
    prev = :ets.prev(tid, key)
    take_prev(tid, prev, n - 1, [%{seq: key, event: event} | acc])
  end

  # ——— GenServer callbacks ———

  @impl true
  def init(:ok) do
    tid = :ets.new(@log_table, [:named_table, :public, :ordered_set, read_concurrency: true])

    {tasks, next_id} = load_from_disk(@default_file)
    state = %{tasks: tasks, next_id: next_id, log_tid: tid}

    {:ok, log(state, :boot, %{loaded: length(tasks), path: @default_file})}
  end

  @impl true
  def handle_call({:add, title, desc}, _from, state) do
    task = %Task{id: state.next_id, title: title, description: desc, status: "todo"}
    new_state =
      %{state | tasks: [task | state.tasks], next_id: state.next_id + 1}
      |> log(:add, %{id: task.id, title: title})
      |> autosave()

    # enqueue background subtasks for this task
    _= JobQueue.enqueue_subtasks(task)

    {:reply, task, new_state}
  end

  @impl true
  def handle_call(:list, _from, state) do
    sorted = Enum.sort_by(state.tasks, & &1.id)
    {:reply, sorted, log(state, :list, %{count: length(sorted)})}
  end

  @impl true
  def handle_call({:done, id}, _from, state) do
    # map_reduce returns {mapped_list, final_acc}
    {tasks, found} =
      Enum.map_reduce(state.tasks, false, fn
        %Task{id: ^id} = t, _ -> {%Task{t | status: "done"}, true}
        t, acc_found -> {t, acc_found}
      end)

    reply = if found, do: :ok, else: {:error, :not_found}

    new_state =
      (if found, do: %{state | tasks: tasks} |> log(:done, %{id: id}), else: state)
      |> autosave_if(found)

    {:reply, reply, new_state}
  end


  @impl true
  def handle_call({:save, path}, _from, state) do
    case write_json(path, state.tasks) do
      :ok -> {:reply, :ok, log(state, :save, %{path: path, count: length(state.tasks)})}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:load, path}, _from, state) do
    {tasks, next_id} = load_from_disk(path)
    new_state = %{state | tasks: tasks, next_id: next_id} |> log(:load, %{path: path, count: length(tasks)})
    {:reply, :ok, new_state}
  end

  # ——— internal helpers ———

  defp load_from_disk(path) do
    case File.read(path) do
      {:ok, contents} ->
        tasks = contents |> Jason.decode!() |> Enum.map(&Task.from_map/1)
        next_id = if tasks == [], do: 1, else: (Enum.max_by(tasks, & &1.id).id + 1)
        {tasks, next_id}
      {:error, :enoent} -> {[], 1}
      {:error, _reason} -> {[], 1} # keep running even if file is corrupt; you can add validation later
    end
  end

  defp write_json(path, tasks), do: tasks |> Jason.encode!() |> then(&File.write(path, &1))

  defp autosave(state) do
    case write_json(@default_file, state.tasks) do
      :ok -> log(state, :autosave, %{path: @default_file, count: length(state.tasks)})
      {:error, reason} -> log(state, :autosave_failed, %{reason: inspect(reason)})
    end
  end

  defp autosave_if(state, true), do: autosave(state)
  defp autosave_if(state, false), do: state

  defp log(state, type, data) do
    seq = :erlang.unique_integer([:monotonic, :positive])
    event = %{ts: DateTime.utc_now(), type: type, data: data}
    true = :ets.insert(state.log_tid, {seq, event})
    trim_log(state.log_tid)
    state
  end

  defp trim_log(tid) do
    case :ets.info(tid, :size) do
      size when is_integer(size) and size > @log_limit ->
        :ets.delete(tid, :ets.first(tid))
        trim_log(tid)
      _ -> :ok
    end
  end
end
