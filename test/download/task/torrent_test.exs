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

      send pid, {0, :data, :out, "===\n[#856840 30MiB/1.0GiB(2%) CN:6 SD:2 DL:2.1MiB UL:12KiB(112KiB) ETA:7m36s]\n]\nFILE: /tmp/asd.mp4\n---"}

      assert_receive {:progress, "/tmp/asd.mp4", 2.0}, 500
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

#"\n\nDownload Results:\ngid   |stat|avg speed  |path/URI\n======+====+===========+=======================================================\n85cdd1|OK  |       0B/s|[MEMORY][METADATA]16b6d9908d770041bb51f0a1849d4abb610f961c\n4b4973|ERR |       0B/s|/tmp/Blue Reflection Full Steam Crack/BLUE REFLECTION.part01.rar (22more)\n\nStatus Legend:\n(OK):download completed.(ERR):error occurred.\n"
#"[#62ce74 0B/0B CN:0 SD:0 DL:0B]\n[#62ce74 0B/0B CN:0 SD:0 DL:0B]\n[#62ce74 0B/0B CN:5 SD:0 DL:0B]\n[#62ce74 0B/40KiB(0%) CN:5 SD:1 DL:0B]\n[#62ce74 40KiB/40KiB(100%) CN:3 SD:1]\n\n04/09 18:51:32 [\e[1;32mNOTICE\e[0m] Download complete: [MEMORY][METADATA]c0244d7d85232339de91fa634e99480677d2ec81\n"
#"[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:0 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:5 SD:0 DL:0B]\n[#856840 0B/1.0GiB(0%) CN:5 SD:1 DL:0B]\n[#856840 16KiB/1.0GiB(0%) CN:5 SD:2 DL:72KiB ETA:4h4m32s]\n[#856840 224KiB/1.0GiB(0%) CN:5 SD:2 DL:182KiB ETA:1h36m31s]\n[#856840 544KiB/1.0GiB(0%) CN:5 SD:2 DL:237KiB ETA:1h14m5s]\n[#856840 1.1MiB/1.0GiB(0%) CN:5 SD:2 DL:346KiB ETA:50m50s]\n[#856840 1.7MiB/1.0GiB(0%) CN:5 SD:2 DL:425KiB ETA:41m21s]\n[#856840 2.4MiB/1.0GiB(0%) CN:5 SD:2 DL:468KiB ETA:37m31s]\n[#856840 3.0MiB/1.0GiB(0%) CN:5 SD:2 DL:496KiB ETA:35m23s]\n[#856840 4.1MiB/1.0GiB(0%) CN:5 SD:2 DL:580KiB ETA:30m13s]\n[#856840 5.3MiB/1.0GiB(0%) CN:7 SD:2 DL:662KiB UL:444KiB(32KiB) ETA:26m27s]\n[#856840 8.3MiB/1.0GiB(0%) CN:7 SD:2 DL:915KiB UL:29KiB(32KiB) ETA:19m5s]\n[#856840 12MiB/1.0GiB(1%) CN:7 SD:2 DL:1.3MiB UL:15KiB(32KiB) ETA:12m27s]\n[#856840 17MiB/1.0GiB(1%) CN:7 SD:2 DL:1.8MiB UL:10KiB(32KiB) ETA:9m7s]\n[#856840 21MiB/1.0GiB(2%) CN:7 SD:2 DL:2.2MiB UL:7.8KiB(32KiB) ETA:7m26s]\n[#856840 22MiB/1.0GiB(2%) CN:7 SD:2 DL:2.3MiB UL:12KiB(64KiB) ETA:7m13s]\n[#856840 23MiB/1.0GiB(2%) CN:7 SD:2 DL:2.3MiB UL:10KiB(64KiB) ETA:7m7s]\n[#856840 24MiB/1.0GiB(2%) CN:7 SD:2 DL:2.3MiB UL:9.0KiB(64KiB) ETA:7m2s]\n[#856840 25MiB/1.0GiB(2%) CN:7 SD:2 DL:2.2MiB UL:7.9KiB(64KiB) ETA:7m24s]\n[#856840 26MiB/1.0GiB(2%) CN:7 SD:2 DL:2.2MiB UL:12KiB(112KiB) ETA:7m18s]\n[#856840 28MiB/1.0GiB(2%) CN:7 SD:2 DL:2.3MiB UL:14KiB(112KiB) ETA:7m4s]\n *** Download Progress Summary as of Mon Apr  9 18:52:25 2018 *** \n===============================================================================\n[#856840 30MiB/1.0GiB(2%) CN:6 SD:2 DL:2.1MiB UL:12KiB(112KiB) ETA:7m36s]\nFILE: /tmp/[Erai-raws] Yowamushi Pedal - Glory Line - 14 [1080p][Multiple Subtitle].mkv\n-------------------------------------------------------------------------------\n\n"
