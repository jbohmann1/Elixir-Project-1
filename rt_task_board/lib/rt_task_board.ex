defmodule RTTaskBoard do
  @moduledoc """
  Core functions for managing tasks in memory and on disk.
  """

  alias RTTaskBoard.Task

  @type task_list :: [Task.t()]
  @default_file "tasks.json"

  # ---------- pure, in-memory ops ----------

  @doc "Compute the next ID based on the existing list."
  def next_id([]), do: 1
  def next_id(tasks), do: (tasks |> Enum.max_by(& &1.id)).id + 1

  @doc "Add a new task to the list."
  def add_task(tasks, title, description \\ "") when is_list(tasks) do
    id = next_id(tasks)

    task = %Task{
      id: id,
      title: title,
      description: description,
      status: "todo"
    }

    [task | tasks]
  end

  @doc "Return tasks sorted by id (useful for printing)."
  def list_tasks(tasks) when is_list(tasks) do
    Enum.sort_by(tasks, & &1.id)
  end

  @doc "Mark a task complete by id."
  def complete_task(tasks, id) when is_list(tasks) and is_integer(id) do
    Enum.map(tasks, fn
      %Task{id: ^id} = t -> %Task{t | status: "done"}
      t -> t
    end)
  end

  # ---------- persistence (JSON file) ----------

  @doc "Save tasks to a JSON file (default: tasks.json)"
  def save(tasks, path \\ @default_file) when is_list(tasks) do
    tasks
    |> Jason.encode!()
    |> then(&File.write(path, &1))
  end

  @doc "Load tasks from a JSON file; returns [] if file is missing."
  def load(path \\ @default_file) do
    case File.read(path) do
      {:ok, contents} ->
        contents
        |> Jason.decode!()
        |> Enum.map(&Task.from_map/1)

      {:error, :enoent} ->
        []

      {:error, reason} ->
        raise File.Error, reason: reason, action: "read file", path: path
    end
  end
end
