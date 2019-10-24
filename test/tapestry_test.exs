defmodule TapestryTest do
  use ExUnit.Case
  doctest Tapestry

  test "greets the world" do
    assert Tapestry.hello() == :world
  end
end
