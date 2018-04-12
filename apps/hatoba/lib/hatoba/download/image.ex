defmodule Hatoba.Download.Image do
  @behaviour Hatoba.Download.Task

  def run(_parent, outpath, arg) do
    resp = arg
    |> HTTPoison.get

    case resp do
      {:ok, resp} ->
        file = arg
        |> Path.split
        |> List.last
        |> URI.decode

        outfile = Path.join(outpath, file)
        case File.write(outfile, resp.body) do
          :ok -> Process.exit(self(), {:success, [file]})
          {:error, reason} -> Process.exit(self(), {:failure, reason})
        end
      _ -> Process.exit(self(), {:failure, "Bad URL or network error."})
    end
  end
end
