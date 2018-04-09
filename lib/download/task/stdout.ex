defmodule Hatoba.Download.Stdout do
  @callback process_data(String.t) :: {:ok, tuple()} | nil
  @callback cmd(any()) :: String.t

  use Task
  alias Porcelain.Result

  def start_link([impl, parent, arg]) do
    Task.start_link(__MODULE__, :run, [impl, parent, arg])
  end

  def run(impl, parent, arg) do
    proc = proc(impl, arg)
    loop(impl, parent, proc)
  end

  def proc(impl, arg) do
    Porcelain.spawn_shell(impl.cmd(arg),
      in: :receive, out: {:send, self()})
  end

  def loop(impl, parent, proc) do
    receive do
      {pid, :data, :out, data} ->
        ^pid = proc.pid
        case impl.process_data(data) do
          {:ok, dat} -> send parent, dat
          _ -> nil
        end
        loop(impl, parent, proc)
      {pid, :result, %Result{status: status}} -> finish(parent, status)
    end
  end

  defp finish(parent, status) do
    case status do
      0 -> send parent, {:success}
      _ -> send parent, {:failure, status}
    end
  end
end
