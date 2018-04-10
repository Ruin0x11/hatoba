defmodule Hatoba.Download.Task do
  use Task

  @callback run(pid(), String.t, any()) :: :success | {:failure, String.t}

  def start_link([_impl, _parent, _path, _arg] = args) do
    Task.start_link(__MODULE__, :run, args)
  end

  def async([_impl, _parent, _path, _arg] = args) do
    Task.async(__MODULE__, :run, args)
  end

  def run(impl, parent, path, arg) do
    impl.run(parent, path, arg)
  end
end
