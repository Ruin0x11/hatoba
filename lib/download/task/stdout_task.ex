defmodule Hatoba.Download.StdoutTask do
  @callback process_stdout(String.t, map(), pid()) :: map()
  @callback cmd(String.t, any()) :: String.t # possibly refactor into multi-command pipeline with separate progress weights?

  use Task
  alias Porcelain.Result

  def start([_impl, _parent, _path, _arg] = args) do
    Task.start(__MODULE__, :run, args)
  end

  def start_link([_impl, _parent, _path, _arg] = args) do
    Task.start_link(__MODULE__, :run, args)
  end

  def async([_impl, _parent, _path, _arg] = args) do
    Task.async(__MODULE__, :run, args)
  end


  def run(impl, parent, path, arg) do
    proc = proc(impl, path, arg)
    loop(impl, parent, proc, %{file: ""})
  end

  def proc(impl, path, arg) do
    Porcelain.spawn_shell(impl.cmd(path, arg),
      in: :receive, out: {:send, self()})
  end

  def loop(impl, parent, proc, child_state) do
    receive do
      {pid, :data, :out, data} ->
        ^pid = proc.pid
        IO.inspect data
        new_state = impl.process_stdout(data, child_state, parent)
        loop(impl, parent, proc, new_state)
      {pid, :result, %Result{status: status}} ->
        ^pid = proc.pid
        Process.exit(self(), finish(status))
    end
  end

  defp finish(status) do
    case status do
      0 -> :success
      _ -> {:failure, status}
    end
  end
end
