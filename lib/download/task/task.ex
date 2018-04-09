defmodule Hatoba.Download.Task do
  use Task

  @callback run(pid(), String.t, any()) :: :success | {:failure, String.t}

  def start_link([impl, parent, path, arg]) do
    Task.start_link(__MODULE__, :run, [impl, parent, path, arg])
  end

  def run(impl, parent, path, arg) do
    impl.run(parent, path, arg)
  end
end
