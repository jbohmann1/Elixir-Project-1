defmodule RTTaskBoard.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [
      {RTTaskBoard.Store, []}
    ]

    opts = [strategy: :one_for_one, name: RTTaskBoard.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
