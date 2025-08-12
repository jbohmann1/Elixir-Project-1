defmodule TaskBoard.Task do
  defstruct [:id, :title, :description, status: :incomplete]
end

defmodule TaskBoard do
  alias TaskBoard.Task

  # Add a task to the list
  def add_task(tasks, title, description) do
    id = generate_id(tasks)
    new_task = %Task{id: id, title: title, description: description}
    tasks ++ [new_task] # append new task to the list
  end

  # List all tasks
  def list_tasks(tasks) do
    Enum.each(tasks, fn task ->
      IO.puts("[#{task.id}] #{task.title} - #{task.status}")
    end)
  end

  # Mark a task as complete by id
  def complete_task(tasks, id) do
    Enum.map(tasks, fn
      %Task{id: ^id} = task -> %{task | status: :complete} # update task
      task -> task
    end)
  end

  # Helper function to generate a new id
  defp generate_id(tasks) do
    max_id = tasks |> Enum.map(& &1.id) |> Enum.max(fn -> 0 end)
    max_id + 1
  end


  # Save tasks list to a JSON file
  def save_tasks(tasks, filename \\ "tasks.json") do
    # Convert tasks to maps (Jason can't encode structs by default)
    tasks
    |> Enum.map(&Map.from_struct/1)
    |> Jason.encode!()
    |> (&File.write(filename, &1)).()
  end

  # Load tasks list from a JSON file
  def load_tasks(filename \\ "tasks.json") do
    case File.read(filename) do
      {:ok, content} ->
        content
        |> Jason.decode!()
        |> Enum.map(&struct(Task, &1))

      {:error, _reason} ->
        []
    end
  end
end
