defmodule Hatoba do
  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Registry.Hatoba},
      {Hatoba.Download.Supervisor, []}
    ]

    opts = [strategy: :one_for_one, name: Hatoba.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
