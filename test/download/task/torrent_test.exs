defmodule Hatoba.Download.TorrentTest do
  use ExUnit.Case, async: false

  import Mock
  alias Porcelain.Result

  def run(url) do
    Hatoba.Download.StdoutTask.start([Hatoba.Download.Torrent, self(), "/tmp", url])
  end

  test "provides progress" do
    with_mock Porcelain, [spawn_shell: fn(_, _) -> %{ :pid => 0 } end] do
      {:ok, pid} = run("https://nyaa.si/download/1.torrent")

      send pid, {0, :data, :out, "===\n[#856840 30MiB/1.0GiB(2%) CN:6 SD:2 DL:2.1MiB UL:12KiB(112KiB) ETA:7m36s]\n"}

      assert_receive {:progress, 2.0}, 500
    end
  end

  test "reports success" do
    with_mock Porcelain, [spawn_shell: fn(_, _) -> %{ :pid => 0 } end] do
      {:ok, pid} = run("https://nyaa.si/download/1.torrent")
      ref = Process.monitor(pid)

      send pid, {0, :result, %Result{status: 0}}

      assert_receive {:DOWN, ^ref, :process, ^pid, :success}, 500
    end
  end

  test "reports failure" do
    with_mock Porcelain, [spawn_shell: fn(_, _) -> %{ :pid => 0 } end] do
      {:ok, pid} = run("https://nyaa.si/download/1.torrent")
      ref = Process.monitor(pid)

      send pid, {0, :data, :out, "(OK):download completed.(ERR):error occurred.\n"}

      assert_receive {:DOWN, ^ref, :process, ^pid, {:failure, "error"}}, 500
    end
  end
end
