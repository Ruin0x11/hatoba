defmodule Hatoba.DownloadTest do
  use ExUnit.Case, async: true

  setup do
    start_supervised!({Hatoba.Download, [0, ""]})
    :ok
  end

  test "continues running even if task crashes" do
    pid = Hatoba.Download.start(0)
    Process.exit(pid, :kill)

    Hatoba.Download.status(0) # bogus sync call to flush messages
    assert Hatoba.Download.status(0) == {:failed, 0}
  end

  test "continues running even if task fails" do
    pid = Hatoba.Download.start(0)
    Process.exit(pid, {:failed, "some error"})

    Hatoba.Download.status(0) # bogus sync call to flush messages
    assert Hatoba.Download.status(0) == {:failed, 0}
  end

  test "continues running even if task exits" do
    pid = Hatoba.Download.start(0)
    Process.exit(pid, :blah)

    Hatoba.Download.status(0) # bogus sync call to flush messages
    assert Hatoba.Download.status(0) == {:failed, 0}
  end
end
