defmodule RTTaskBoard.Job do
  @moduledoc "Background job for a given task."

  @derive {Jason.Encoder, only: [
    :id, :task_id, :type, :args, :status,
    :attempts, :max_attempts, :last_error,
    :inserted_at, :updated_at, :started_at, :finished_at,
    :result
  ]}

  @enforce_keys [:id, :task_id, :type]
  defstruct id: nil,
            task_id: nil,
            type: nil,           # atom or string describing the kind of job
            args: %{},           # job-specific data
            status: :pending,    # :pending | :running | :completed | :failed
            attempts: 0,
            max_attempts: 3,
            last_error: nil,
            inserted_at: nil,
            updated_at: nil,
            started_at: nil,
            finished_at: nil,
            result: nil
end
