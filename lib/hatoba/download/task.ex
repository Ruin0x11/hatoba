defmodule Hatoba.Download.Task do
  use Task

  @callback run(pid(), String.t, any()) :: :success | {:failure, String.t}

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
    impl.run(parent, path, arg)
  end

  def from_source_type(type) do
    case type do
      #:image   -> {Hatoba.Download.Task,       Hatoba.Download.Image}
      :torrent -> {Hatoba.Download.StdoutTask, Hatoba.Download.Torrent}
      :booru   -> {Hatoba.Download.Task,       Hatoba.Download.Booru}
      #:booru2  -> {Hatoba.Download.Task,       Hatoba.Download.Booru2}
      :video   -> {Hatoba.Download.StdoutTask, Hatoba.Download.Youtube}
      _ -> {nil, nil}
    end
  end
end
