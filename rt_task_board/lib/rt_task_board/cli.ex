defmodule RTTaskBoard.CLI do
  @moduledoc """
  Minimal command-line interface:
    list
    add <title> [description...]
    done <id>
    save [path]
    load [path]
  """

  alias RTTaskBoard
  alias RTTaskBoard.Task

  def main(argv) do
    case argv do
      ["help"] -> print_help()

      ["list"] ->
        RTTaskBoard.load()
        |> RTTaskBoard.list_tasks()
        |> print_tasks()

      ["add", title] ->
        tasks = RTTaskBoard.load()
        tasks = RTTaskBoard.add_task(tasks, title)
        :ok = RTTaskBoard.save(tasks)
        IO.puts("Added: #{title}")

      ["add" | rest] ->
        # If you pass two quoted strings: title, description
        {title, desc} = split_title_and_desc(rest)
        tasks = RTTaskBoard.load()
        tasks = RTTaskBoard.add_task(tasks, title, desc)
        :ok = RTTaskBoard.save(tasks)
        IO.puts("Added: #{title}")

      ["done", id_str] ->
        tasks = RTTaskBoard.load()

        case Integer.parse(id_str) do
          {id, ""} ->
            tasks = RTTaskBoard.complete_task(tasks, id)
            :ok = RTTaskBoard.save(tasks)
            IO.puts("Marked #{id} as done.")

          _ ->
            IO.puts(:stderr, "Invalid id: #{id_str}")
        end

      ["save", path] ->
        :ok = RTTaskBoard.load() |> RTTaskBoard.save(path)
        IO.puts("Saved to #{path}")

      ["load", path] ->
        tasks = RTTaskBoard.load(path)
        :ok = RTTaskBoard.save(tasks) # copy into default tasks.json
        IO.puts("Loaded #{length(tasks)} tasks from #{path}.")

      _ ->
        print_help()
    end
  end

  defp split_title_and_desc([title]), do: {title, ""}
  defp split_title_and_desc([title | desc_words]), do: {title, Enum.join(desc_words, " ")}

  defp print_help do
    IO.puts("""
    Usage:
      rt_task_board list
      rt_task_board add <title> [description...]
      rt_task_board done <id>
      rt_task_board save <path>
      rt_task_board load <path>

    Examples:
      rt_task_board add "Buy milk" "2% organic"
      rt_task_board list
      rt_task_board done 1
      rt_task_board save tasks_backup.json
      rt_task_board load tasks_backup.json
    """)
  end

  defp print_tasks(tasks) do
    for %Task{id: id, title: title, description: desc, status: status} <- tasks do
      marker = if status == "done", do: "[x]", else: "[ ]"
      desc_part =
        case desc do
          nil -> ""
          "" -> ""
          d -> " — " <> d
        end

      IO.puts("#{marker} #{id}: #{title}#{desc_part}")
    end
  end
end
