defmodule RTTaskBoard.Events do
  @moduledoc """
  Small helper to (optionally) broadcast domain events via Phoenix.PubSub.
  If Phoenix isn't present, this no-ops.
  """

  @topic "rt:events"

  def topic, do: @topic

  # examples:
  # broadcast(:task_added, task)
  # broadcast(:task_updated, task)
  # broadcast(:job_updated, job)
  def broadcast(type, payload) do
    case Application.get_env(:rt_task_board, :pubsub) do
      nil -> :ok
      pubsub ->
        if Code.ensure_loaded?(Phoenix.PubSub) do
          Phoenix.PubSub.broadcast(pubsub, @topic, {:rt_event, type, payload})
        else
          :ok
        end
    end
  end
end
