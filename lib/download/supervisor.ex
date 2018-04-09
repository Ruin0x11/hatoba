defmodule Hatoba.Download.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {Task.Supervisor, name: Hatoba.TaskSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
