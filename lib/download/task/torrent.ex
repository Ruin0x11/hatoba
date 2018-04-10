defmodule Hatoba.Download.Torrent do
  @behaviour Hatoba.Download.StdoutTask

  def process_stdout(data) do
    progress = Regex.run(~r/===\n\[#\w+ .*\/.*\(([0-9]+)%\) .*/, data)
    case progress do
      [_, amount]  -> if {num, _} = Float.parse(amount), do: {:ok, {:progress, num}}
      _ -> cond do
          String.contains?(data, "(ERR):error occurred.") -> Process.exit(self(), {:failure, "error"})
          true -> nil
        end
    end
  end

  def cmd(path, url), do: "aria2c --seed-time=0 -d #{path} #{url}"
end
