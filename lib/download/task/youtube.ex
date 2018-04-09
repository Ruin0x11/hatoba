defmodule Hatoba.Download.Youtube do
  @behaviour Hatoba.Download.Stdout

  def process_data(data) do
    cond do
      [_, amount] = Regex.run(~r/.*\[download\] ([0-9]+)% of .*/, data) ->
        with {num, _} <- Integer.parse(amount), do: {:ok, {:progress, num}}
      true -> nil
    end
  end

  def cmd(url), do: "youtube-dl #{url}"
end
