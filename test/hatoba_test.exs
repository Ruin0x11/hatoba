defmodule HatobaTest do
  use ExUnit.Case
  doctest Hatoba

  test "greets the world" do
    assert Hatoba.hello() == :world
  end
end
