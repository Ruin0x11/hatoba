defmodule Hatoba.Upload.Task do
  use Task

  @callback run(pid(), Hatoba.Download.t, any()) :: :success | {:failure, String.t}
  @callback validate(Hatoba.Download.t, any()) :: :ok | {:error, any()}

  def start([_impl, _parent, _dl, _arg] = args) do
    Task.start(__MODULE__, :run, args)
  end

  def start_link([_impl, _parent, _dl, _arg] = args) do
    Task.start_link(__MODULE__, :run, args)
  end

  def async([_impl, _parent, _dl, _arg] = args) do
    Task.async(__MODULE__, :run, args)
  end

  def validate(impl, dl, arg) do
    if Hatoba.Download.valid?(dl) do
      case dl.status do
        :success -> impl.validate(dl, arg)
        status -> {:error, "Can't upload unsuccessful download. Status was: #{status}"}
      end
    else
      {:error, "Not all files in the download exist on the filesystem!"}
    end
  end

  def run(impl, parent, dl, arg) do
    case validate(impl, dl, arg) do
      :ok -> impl.run(parent, dl)
      {:error, reason} -> {:failure, reason}
    end
  end

  def from_upload_type(type) do
    case type do
      :booru  -> Hatoba.Upload.Booru
      :move   -> Hatoba.Upload.Move
      :remote -> Hatoba.Upload.Remote
      _ -> nil
    end
  end
end
