defmodule Hatoba.DownloadTest do
  use ExUnit.Case, async: true

  setup do
    start_supervised!({Hatoba.Download, [0, ""]})
    :ok
  end

  test "continues running even if task crashes" do
    pid = Hatoba.Download.start(0)
    ref = Process.monitor(pid)

    Process.exit(pid, :kill)

    receive do
      {:DOWN, ^ref, _, _, _} -> :task_is_down
    after
      1_000 -> raise "Proecss didn't exit"
    end

    Hatoba.Download.status(0) # bogus sync call to flush messages
    assert Hatoba.Download.status(0) == {:failed, 0}
  end

  test "continues running even if task fails" do
    pid = Hatoba.Download.start(0)
    ref = Process.monitor(pid)

    Process.exit(pid, {:failed, "some error"})

    receive do
      {:DOWN, ^ref, _, _, _} -> :task_is_down
    after
      1_000 -> raise "Proecss didn't exit"
    end

    Hatoba.Download.status(0) # bogus sync call to flush messages
    assert Hatoba.Download.status(0) == {:failed, 0}
  end

  test "continues running even if task exits" do
    pid = Hatoba.Download.start(0)
    ref = Process.monitor(pid)

    Process.exit(pid, :blah)

    receive do
      {:DOWN, ^ref, _, _, _} -> :task_is_down
    after
      1_000 -> raise "Proecss didn't exit"
    end

    Hatoba.Download.status(0) # bogus sync call to flush messages
    assert Hatoba.Download.status(0) == {:failed, 0}
  end
end
