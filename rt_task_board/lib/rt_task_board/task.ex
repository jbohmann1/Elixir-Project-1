defmodule RTTaskBoard.Task do
  @moduledoc """
  A single task in the board.
  """

  # Let Jason encode the struct to JSON with just these fields
  @derive {Jason.Encoder, only: [:id, :title, :description, :status]}

  @enforce_keys [:id, :title, :status]
  defstruct [:id, :title, :description, :status]

  @type t :: %__MODULE__{
          id: integer(),
          title: String.t(),
          description: String.t() | nil,
          status: String.t() # "todo" | "done"
        }

  @doc "Build a struct from a map decoded from JSON."
  def from_map(%{"id" => id, "title" => title, "description" => desc, "status" => status}) do
    %__MODULE__{id: id, title: title, description: desc, status: status}
  end

  def from_map(%{"id" => id, "title" => title, "status" => status}) do
    %__MODULE__{id: id, title: title, description: nil, status: status}
  end
end
