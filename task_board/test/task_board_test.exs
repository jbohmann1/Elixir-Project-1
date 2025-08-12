defmodule TaskBoardTest do
  use ExUnit.Case
  doctest TaskBoard

  test "greets the world" do
    assert TaskBoard.hello() == :world
  end
end
