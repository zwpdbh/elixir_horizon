defmodule How.Parse.Example01Test do
  alias How.Parse.Example01
  use ExUnit.Case

  test "hello world" do
    # mix test apps/elixir_in_action/test/how/parse/example_01_test.exs:5
    {:ok, [2010, 4, 17, 14, 12, 34, "Z"], "", %{}, {1, 0}, 20} =
      Example01.datetime("2010-04-17T14:12:34Z")
  end
end
