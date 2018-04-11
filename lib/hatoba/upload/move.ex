defmodule Hatoba.Upload.Move do
  @behaviour Hatoba.Upload.Task

  def run(_parent, dl, arg) do
    errors = dl
    |> Hatoba.Download.files
    |> Enum.map(&(cp(&1, arg)))
    |> Enum.filter(fn(x) -> is_tuple(x) end)
    |> Enum.map(&Tuple.to_list(&1) |> List.last)

    if Enum.empty?(errors) do
      :success
    else
      {:failure, Enum.join(errors, "\n")}
    end
  end

  def validate(_dl, arg) do
    # test if directory can be created
    File.mkdir_p(arg)
  end

  defp cp(source, destdir) do
    dest = source
    |> Path.split
    |> List.last
    |> (&(Path.join(destdir, &1))).()
    IO.puts dest
    IO.puts source
    case File.cp(source, dest) do
      :ok -> :success
      {:error, reason} -> {:failure, reason}
    end
  end
end
