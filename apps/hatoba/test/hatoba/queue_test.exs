defmodule Hatoba.QueueTest do
  use ExUnit.Case

  defp items, do: Enum.map(0..12, fn(a) -> "https://yande.re/post/show/#{Enum.random(1..99999)}" end)

  test "immediately fails unknown links" do
    assert false
  end

  test "sends to failed when download fails" do
    assert false
  end

  test "sends to upload when download succeeds" do
    assert false
  end

  test "sends to uploads_failed when upload fails" do
    assert false
  end

  test "sends to finished when upload succeeds" do
    assert false
  end
end
