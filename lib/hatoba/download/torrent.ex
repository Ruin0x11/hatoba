defmodule Hatoba.Download.Torrent do
  @behaviour Hatoba.Download.StdoutTask

  def process_stdout(data, state, parent) do
    progress = Regex.run(~r/\[#\w+.*\/.*\(([0-9]+)%\) .*/, data)
    dest = Regex.run(~r/\nFILE: (.*)\n---/, data)

    new_state = case dest do
      [_, path] -> %{state | file: path}
      _ -> state
    end

    case progress do
      [_, amount]  -> if {num, _} = Float.parse(amount),
                      do: send parent, {:progress, new_state.file, num}
      _ -> cond do
          String.contains?(data, "(ERR):error occurred.") -> Process.exit(self(), {:failure, "error"})
          true -> nil
        end
    end

    new_state
  end

  def cmd(path, url), do: "aria2c --seed-time=0 -d #{path} #{url}"
end
