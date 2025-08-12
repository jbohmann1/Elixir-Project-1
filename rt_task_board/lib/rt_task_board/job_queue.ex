defmodule RTTaskBoard.JobQueue do
  @moduledoc """
  In-memory job queue with max_concurrency and retries.
  Uses Task.Supervisor to run jobs concurrently.
  """

  use GenServer
  alias RTTaskBoard.{Job, Workers}

  @name __MODULE__
  @max_concurrency 4
  @backoff_min 1_000      # 1s
  @backoff_max 30_000     # 30s

  # ---------- Public API ----------

  def start_link(_args), do: GenServer.start_link(__MODULE__, :ok, name: @name)

  # Add a job (returns job struct)
  def enqueue(job_spec), do: GenServer.call(@name, {:enqueue, job_spec})

  # Helper: enqueue default subtasks for a task
  def enqueue_subtasks(%{id: task_id, title: title, description: desc}) do
    GenServer.call(@name, {:enqueue_subtasks, task_id, title, desc})
  end

  # Read-only APIs
  def jobs, do: GenServer.call(@name, :jobs)
  def jobs_by_status(status), do: GenServer.call(@name, {:jobs_by_status, status})
  def job(id), do: GenServer.call(@name, {:job, id})

  # ---------- GenServer ----------

  @impl true
  def init(:ok) do
    state = %{
      next_id: 1,
      jobs: %{},                # id => %Job{}
      pending: :queue.new(),    # FIFO of job ids
      running: %{},             # id => %{pid: pid, ref: ref}
      max_concurrency: @max_concurrency
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:enqueue, job_spec}, _from, state) do
    {job, state} = new_job(state, job_spec)
    state = state |> push_pending(job.id) |> maybe_start_more()
    {:reply, job, state}
  end

  @impl true
  def handle_call({:enqueue_subtasks, task_id, title, desc}, _from, state) do
    # Example pipeline: analyze text -> maybe_fail -> notify
    {j1, state} = new_job(state, %{task_id: task_id, type: :analyze_text, args: %{"title" => title, "description" => desc}})
    {j2, state} = new_job(state, %{task_id: task_id, type: :maybe_fail,   args: %{"fail_rate" => 0.3}})
    {j3, state} = new_job(state, %{task_id: task_id, type: :notify,       args: %{"user" => "team@example"}})

    state = state
            |> push_pending(j1.id)
            |> push_pending(j2.id)
            |> push_pending(j3.id)
            |> maybe_start_more()

    {:reply, [j1, j2, j3], state}
  end

  @impl true
  def handle_call(:jobs, _from, state) do
    {:reply, state.jobs |> Map.values() |> Enum.sort_by(& &1.id), state}
  end

  def handle_call({:jobs_by_status, status}, _from, state) do
    list =
      state.jobs
      |> Map.values()
      |> Enum.filter(&(&1.status == status))
      |> Enum.sort_by(& &1.id)

    {:reply, list, state}
  end

  def handle_call({:job, id}, _from, state) do
    {:reply, Map.get(state.jobs, id), state}
  end

  @impl true
  def handle_info(:maybe_start, state), do: {:noreply, maybe_start_more(state)}

  # Worker sends this message on success/failure
  def handle_info({:job_result, id, {:ok, result}}, state) do
    {_value, running} = Map.pop(state.running, id)
    now = DateTime.utc_now()

    job =
      state.jobs
      |> Map.fetch!(id)
      |> Map.merge(%{status: :completed, last_error: nil, finished_at: now, updated_at: now, result: result})

    state = %{state | running: running, jobs: Map.put(state.jobs, id, job)}
    {:noreply, maybe_start_more(state)}
  end

  def handle_info({:job_result, id, {:error, reason}}, state) do
    {_value, running} = Map.pop(state.running, id)
    job = Map.fetch!(state.jobs, id)
    now = DateTime.utc_now()
    attempts = job.attempts

    if attempts + 1 < job.max_attempts do
      backoff = backoff_ms(attempts + 1)
      new_job = %{job | status: :pending, attempts: attempts + 1, last_error: inspect(reason), updated_at: now, finished_at: now}
      state = %{state | running: running, jobs: Map.put(state.jobs, id, new_job)}
      Process.send_after(self(), {:retry_job, id}, backoff)
      {:noreply, state}
    else
      new_job = %{job | status: :failed, attempts: attempts + 1, last_error: inspect(reason), updated_at: now, finished_at: now}
      state = %{state | running: running, jobs: Map.put(state.jobs, id, new_job)}
      {:noreply, maybe_start_more(state)}
    end
  end

  # If a worker crashes before sending :job_result
  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    case Enum.find(state.running, fn {_id, %{ref: r}} -> r == ref end) do
     {id, _info} ->
        case reason do
          :normal -> {:noreply, state}  # success path handled by {:job_result, ...}
           _ -> send(self(), {:job_result, id, {:error, reason}}); {:noreply, state}
        end
      nil -> {:noreply, state}
    end
  end

  def handle_info({:retry_job, id}, state) do
    # Only requeue if job is still pending (hasn't been manually modified)
    case Map.get(state.jobs, id) do
      %Job{status: :pending} ->
        state = state |> push_pending(id) |> maybe_start_more()
        {:noreply, state}
      _ ->
        {:noreply, state}
    end
  end

  # ---------- internals ----------

  defp new_job(state, %{task_id: task_id, type: type, args: args} = _spec) do
    id = state.next_id
    now = DateTime.utc_now()
    job = %Job{
      id: id, task_id: task_id, type: type, args: args || %{},
      status: :pending, attempts: 0, max_attempts: 3, inserted_at: now, updated_at: now
    }

    {job, %{state | next_id: id + 1, jobs: Map.put(state.jobs, id, job)}}
  end

  defp push_pending(state, id) do
    %{state | pending: :queue.in(id, state.pending)}
  end

  # Try to start as many jobs as allowed by max_concurrency
  defp maybe_start_more(state) do
    cond do
      map_size(state.running) >= state.max_concurrency ->
        state

      true ->
        case :queue.out(state.pending) do
          {{:value, id}, rest} ->
            state = %{state | pending: rest}
            case Map.get(state.jobs, id) do
              %Job{status: :pending} = job -> start_job(state, job) |> maybe_start_more()
              _ -> maybe_start_more(state) # skip if job disappeared/changed
            end

          {:empty, _} ->
            state
        end
    end
  end

  defp start_job(state, %Job{} = job) do
    now = DateTime.utc_now()
    job = %{job | status: :running, started_at: now, updated_at: now}
    parent = self()
    task_fun = fn ->
      result =
        try do
          Workers.perform(job)
        rescue
          e -> {:error, e}
        catch
          :exit, reason -> {:error, {:exit, reason}}
          :throw, term -> {:error, {:throw, term}}
        end

      send(self(), {:job_result, job.id, result})
    end

    {:ok, pid} = Task.Supervisor.start_child(RTTaskBoard.JobTaskSupervisor, task_fun)
    ref = Process.monitor(pid)

    running = Map.put(state.running, job.id, %{pid: pid, ref: ref})
    jobs = Map.put(state.jobs, job.id, %{job | attempts: job.attempts + 1})
    state = %{state | running: running, jobs: jobs}
    state
  end

  defp backoff_ms(attempt_number) do
    # 1s, 2s, 4s, 8s ... capped
    ms = trunc(:math.pow(2, attempt_number - 1) * @backoff_min)
    min(ms, @backoff_max)
  end
end
