defmodule Hatoba.Download.Youtube do
  @behaviour Hatoba.Download.StdoutTask

  def process_stdout(data) do
    IO.inspect data
    progress = Regex.run(~r/.*\[download\] ([0-9]+)% of .*/, data)
    case progress do
      [_, amount]  -> with {num, _} <- Float.parse(amount), do: {:ok, {:progress, num}}
      _ -> nil
    end
  end

  def cmd(path, url), do: "youtube-dl -o \"#{path}/%(title)s-%(id)s.%(ext)s\" #{url}"
end
