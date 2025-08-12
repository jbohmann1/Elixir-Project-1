defmodule RTTaskBoard.Workers do
  @moduledoc """
  Functions that actually 'do' jobs. Keep them pure if possible;
  raise on failure so the queue can retry.
  """

  alias RTTaskBoard.Job

  # Simulate analyzing a task's text (counts words)
  def perform(%Job{type: :analyze_text, args: %{"title" => title, "description" => desc}}) do
    text = Enum.join([title, desc || ""], " ")
    cnt = text |> String.split(~r/\s+/, trim: true) |> length()
    # you could persist results somewhere; for demo we just sleep & return
    Process.sleep(200)
    {:ok, %{word_count: cnt}}
  end

  # Pretend to send a notification
  def perform(%Job{type: :notify, args: %{"user" => user}}) do
    # simulate network I/O
    Process.sleep(300)
    {:ok, %{notified: user}}
  end

  # Demonstrate retries by failing sometimes
  def perform(%Job{type: :maybe_fail, args: %{"fail_rate" => rate}}) do
    Process.sleep(100)
    if :rand.uniform() < rate do
      raise "random failure"
    else
      {:ok, :passed}
    end
  end

  # Unknown job types
  def perform(%Job{type: other}) do
    raise "unknown job type: #{inspect(other)}"
  end
end
