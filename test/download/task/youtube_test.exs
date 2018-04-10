defmodule Hatoba.Download.YoutubeTest do
  use ExUnit.Case, async: false

  import Mock
  alias Porcelain.Result

  def run(url) do
    Hatoba.Download.StdoutTask.start([Hatoba.Download.Youtube, self(), "/tmp", url])
  end

  test "provides progress" do
    with_mock Porcelain, [spawn_shell: fn(_, _) -> %{ :pid => 0 } end] do
      {:ok, pid} = run("http://www.youtube.com/watch?v=12345")
      Process.monitor(pid)

      send pid, {0, :data, :out, "[youtube-dl] a message"}
      send pid, {0, :data, :out, "[download] 34% of 10MB"}

      assert_receive {:progress, 34.0}, 500
    end
  end

  test "reports success" do
    with_mock Porcelain, [spawn_shell: fn(_, _) -> %{ :pid => 0 } end] do
      {:ok, pid} = run("http://www.youtube.com/watch?v=12345")
      ref = Process.monitor(pid)

      send pid, {0, :result, %Result{status: 0}}

      assert_receive {:DOWN, ^ref, :process, ^pid, :success}, 500
    end
  end

  test "reports failure" do
    with_mock Porcelain, [spawn_shell: fn(_, _) -> %{ :pid => 0 } end] do
      {:ok, pid} = run("http://www.youtube.com/watch?v=12345")
      ref = Process.monitor(pid)

      send pid, {0, :result, %Result{status: 1}}

      assert_receive {:DOWN, ^ref, :process, ^pid, {:failure, 1}}, 500
    end
  end
end
