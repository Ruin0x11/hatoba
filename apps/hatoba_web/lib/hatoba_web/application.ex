defmodule HatobaWeb.Application do
  use Application

  def start(_type, _args) do
    children = [
      {HatobaWeb.Endpoint, []},
    ]

    opts = [strategy: :one_for_one, name: HatobaWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    HatobaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
