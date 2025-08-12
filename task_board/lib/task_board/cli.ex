defmodule TaskBoard.CLI do
  alias TaskBoard

  def main(args) do
    tasks = TaskBoard.load_tasks()

    case args do
      ["add", title | desc_parts] ->
        description = Enum.join(desc_parts, "")
        tasks = TaskBoard.add_task(tasks, title, description)
        TaskBoard.save_tasks(tasks)
        IO.puts("Task added.")

      ["list"] ->
        TaskBoard.list_tasks(tasks)

      ["complete", id_str] ->
        {id, _} = Integer.parse(id_str)
        tasks = TaskBoard.complete_task(tasks, id)
        TaskBoard.save_tasks(tasks)
        IO.puts("Task marked as complete.")

      _ ->
        IO.puts("Commands:")
        IO.puts(" task_board add <title> <description>")
        IO.puts(" task_board list")
        IO.puts(" task_board complete <id>")
    end
  end
end
