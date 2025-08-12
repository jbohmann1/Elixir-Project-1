defmodule RTTaskBoard.CLI do
  @moduledoc """
  Commands:
    list
    add <title> [description...]
    done <id>
    save [path]
    load [path]
    log [n]     # show recent activity (ETS)
  """

  alias RTTaskBoard.Store
  alias RTTaskBoard.Task

  def main(argv) do
    # Ensure the OTP app (and thus our Supervisor + Store) is started when running as an escript
    {:ok, _} = Application.ensure_all_started(:rt_task_board)

    case argv do
      ["help"] -> print_help()

      ["list"] ->
        Store.list() |> print_tasks()

      ["add", title] ->
        %Task{id: id} = Store.add(title, "")
        IO.puts("Added ##{id}: #{title}")

      ["add" | rest] ->
        {title, desc} = split_title_and_desc(rest)
        %Task{id: id} = Store.add(title, desc)
        IO.puts("Added ##{id}: #{title}")

      ["done", id_str] ->
        with {id, ""} <- Integer.parse(id_str),
             :ok <- Store.done(id) do
          IO.puts("Marked ##{id} as done.")
        else
          :error -> IO.puts(:stderr, "Invalid id: #{id_str}")
          {:error, :not_found} -> IO.puts(:stderr, "No task with id #{id_str}")
        end

      ["save"] ->
        case Store.save() do
          :ok -> IO.puts("Saved to tasks.json")
          {:error, reason} -> IO.puts(:stderr, "Save failed: #{inspect(reason)}")
        end

      ["save", path] ->
        case Store.save(path) do
          :ok -> IO.puts("Saved to #{path}")
          {:error, reason} -> IO.puts(:stderr, "Save failed: #{inspect(reason)}")
        end

      ["load"] ->
        :ok = Store.load()
        IO.puts("Loaded from tasks.json")

      ["load", path] ->
        :ok = Store.load(path)
        IO.puts("Loaded from #{path}")

      ["log"] ->
        print_log(Store.recent(20))

      ["log", n_str] ->
        case Integer.parse(n_str) do
          {n, ""} when n > 0 -> print_log(Store.recent(n))
          _ -> IO.puts(:stderr, "Invalid number: #{n_str}")
        end

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
      rt_task_board save [path]
      rt_task_board load [path]
      rt_task_board log [n]
    """)
  end


  defp print_tasks([]) do
    IO.puts("No tasks yet. Add one with: rt_task_board add \"Title\" [description]")
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

  defp print_log(entries) do
    # entries are newest-first
    for %{seq: seq, event: %{ts: ts, type: type, data: data}} <- entries do
      ts_str =
        case ts do
          %DateTime{} = dt -> DateTime.to_iso8601(dt)
          _ -> inspect(ts)
        end

      IO.puts("[#{seq}] #{ts_str} #{inspect(type)} #{inspect(data)}")
    end
  end
end
