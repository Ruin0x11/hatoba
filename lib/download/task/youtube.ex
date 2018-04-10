defmodule Hatoba.Download.Youtube do
  @behaviour Hatoba.Download.StdoutTask

  def process_stdout(data, state, parent) do
    IO.inspect data
    progress = Regex.run(~r/\[download\]\s+([0-9.]+)%/, data)
    dest = Regex.run(~r/\[download\] Destination: (.*)/, data)

    new_state = case dest do
      [_, path] -> %{state | file: path}
      _ -> state
    end

    case progress do
      [_, amount]  -> with {num, _} <- Float.parse(amount),
                      do: send parent, {:progress, new_state.file, num}
      _ -> nil
    end

    new_state
  end

  def cmd(path, url), do: "youtube-dl -o \"#{path}/%(title)s-%(id)s.%(ext)s\" #{url}"
end
