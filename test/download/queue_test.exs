defmodule Hatoba.QueueTest do
  use ExUnit.Case

  defp items, do: Enum.map(0..12, fn(a) -> "https://yande.re/post/show/#{Enum.random(1..99999)}" end)
end
