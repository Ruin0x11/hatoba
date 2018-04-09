defmodule Hatoba.Download.YoutubeTest do
  use ExUnit.Case, async: false

  import Mock
  alias Porcelain.Result

  def run(url) do
    Hatoba.Download.StdoutTask.async([Hatoba.Download.Youtube, self(), "/tmp", url])
  end

  test "provides progress" do
    with_mock Porcelain, [spawn_shell: fn(_, _) -> %{ :pid => 0 } end] do
      %Task{pid: pid} = run("http://www.youtube.com/watch?v=12345")

      send pid, {0, :data, :out, "[download] 34% of 10MB"}

      assert_receive {:progress, 34}, 500
    end
  end

  test "reports success" do
    with_mock Porcelain, [spawn_shell: fn(_, _) -> %{ :pid => 0 } end] do
      task = %Task{pid: pid} = run("http://www.youtube.com/watch?v=12345")

      send pid, {0, :result, %Result{status: 0}}

      assert Task.await(task, 500) == :success
    end
  end

  test "reports failure" do
    with_mock Porcelain, [spawn_shell: fn(_, _) -> %{ :pid => 0 } end] do
      task = %Task{pid: pid} = run("http://www.youtube.com/watch?v=12345")

      send pid, {0, :result, %Result{status: 1}}

      assert Task.await(task, 500) == {:failure, 1}
    end
  end
end
