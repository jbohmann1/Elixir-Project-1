defmodule RTTaskBoard.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [
      # Workers will run under this supervisor
      {Task.Supervisor, name: RTTaskBoard.JobTaskSupervisor, strategy: :one_for_one},
      # Job queue (manages pending/running/retries)
      {RTTaskBoard.JobQueue, []},
      # Your Stage-2 store (in-memory tasks + autosave/autoload)
      {RTTaskBoard.Store, []}
    ]

    opts = [strategy: :one_for_one, name: RTTaskBoard.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
