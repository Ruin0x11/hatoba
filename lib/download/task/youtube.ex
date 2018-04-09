defmodule Hatoba.Download.Youtube do
  @behaviour Hatoba.Download.StdoutTask

  ## TODO: start_link as part of behaviour

  def process_data(data) do
    cond do
      [_, amount] = Regex.run(~r/.*\[download\] ([0-9]+)% of .*/, data) ->
        with {num, _} <- Integer.parse(amount), do: {:ok, {:progress, num}}
      true -> nil
    end
  end

  def cmd(path, url), do: "youtube-dl -o #{path}/%(title)s-%(id)s.%(ext)s #{url}"
end
