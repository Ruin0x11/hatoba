defmodule Hatoba.Download.YoutubeTest do
  use ExUnit.Case, async: false

  import Mock
  alias Porcelain.Result

  test "provides progress" do
    with_mock Porcelain, [spawn_shell: fn(_, _) -> %{ :pid => 0 } end] do
      {:ok, pid} = Hatoba.Download.Youtube.start_link([self(), "http://www.youtube.com/watch?v=12345"])

      send pid, {0, :data, :out, "[download] 34% of 10MB"}

      assert_receive {:progress, 34}, 500
    end
  end

  test "reports success" do
    with_mock Porcelain, [spawn_shell: fn(_, _) -> %{ :pid => 0 } end] do
      {:ok, pid} = Hatoba.Download.Youtube.start_link([self(), "http://www.youtube.com/watch?v=12345"])

      send pid, {0, :result, %Result{status: 0}}

      assert_receive {:success}, 500
    end
  end

  test "reports failure" do
    with_mock Porcelain, [spawn_shell: fn(_, _) -> %{ :pid => 0 } end] do
      {:ok, pid} = Hatoba.Download.Youtube.start_link([self(), "http://www.youtube.com/watch?v=12345"])

      send pid, {0, :result, %Result{status: 1}}

      assert_receive {:failure, 1}, 500
    end
  end
end
