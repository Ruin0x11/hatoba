defmodule Hatoba.Download.Youtube do
  alias Porcelain.Result

  use Task

  def start_link([parent, url]) do
    Task.start_link(__MODULE__, :run, [parent, url])
  end

  def run(parent, url) do
    proc = proc(url)
    loop(parent, proc)
  end

  def loop(parent, proc) do
    receive do
      {pid, :data, :out, data} ->
        ^pid = proc.pid
        process_data(parent, data)
        loop(parent, proc)
      {pid, :result, %Result{status: status}} -> finish(parent, status)
    end
  end

  defp process_data(parent, data) do
    cond do
      [_, amount] = Regex.run(~r/.*\[download\] ([0-9]+)% of .*/, data) ->
        with {num, _} <- Integer.parse(amount), do: progress(parent, num)
      true -> nil
    end
  end

  def proc(url) do
    Porcelain.spawn_shell("youtube-dl #{url}",
      in: :receive, out: {:send, self()})
  end

  defp finish(parent, status) do
    case status do
      0 -> success(parent)
      _ -> failure(parent, status)
    end
  end

  defp progress(parent, amount) do
    send parent, {:progress, amount}
  end

  defp success(parent) do
    send parent, {:success}
  end

  defp failure(parent, status) do
    send parent, {:failure, status}
  end
end
