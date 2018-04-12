defmodule Hatoba.Download.YoutubeTest do
  use ExUnit.Case, async: false

  import Mock
  alias Porcelain.Result

  def run(url) do
    Hatoba.Download.StdoutTask.start([Hatoba.Download.Youtube, self(), "/tmp", url])
  end

  setup_with_mocks([
    {Porcelain, [], [spawn_shell: fn(_, _) -> %{ :pid => 0 } end]},
  ]) do
    {:ok, foo: "foo"}
  end

  test "provides progress" do
    {:ok, pid} = run("http://www.youtube.com/watch?v=12345")
    Process.monitor(pid)

    send pid, {0, :data, :out, "[download] Destination: /tmp/asd.mp4\n"}
    send pid, {0, :data, :out, "[youtube-dl] a message"}
    send pid, {0, :data, :out, "\r\e[K[download]   0.5% of 11.24MiB at 19.11MiB/s ETA 00:00"}

    assert_receive {:progress, "/tmp/asd.mp4", 0.5}, 500
  end

  test "provides filecount" do
    {:ok, pid} = run("http://www.youtube.com/watch?v=12345")

    send pid, {0, :data, :out, "[youtube:playlist] playlist A Playlist: Downloading 105 videos"}

    assert_receive {:filecount, 105}, 500
  end

  test "reports success" do
    {:ok, pid} = run("http://www.youtube.com/watch?v=12345")
    ref = Process.monitor(pid)

    send pid, {0, :result, %Result{status: 0}}

    assert_receive {:DOWN, ^ref, :process, ^pid, :success}, 500
  end

  test "reports failure" do
    {:ok, pid} = run("http://www.youtube.com/watch?v=12345")
    ref = Process.monitor(pid)

    send pid, {0, :result, %Result{status: 1}}

    assert_receive {:DOWN, ^ref, :process, ^pid, {:failure, 1}}, 500
  end
end
