defmodule How.Snippets.Tmp01Test do
  use ExUnit.Case
  alias How.Snippets.Tmp01

  setup do
    # global setup
    :ok
  end

  describe "tmp01 test" do
    #  mix test apps/elixir_in_action/test/how/snippets/tmp01_test.exs:12
    test "add" do
      assert Tmp01.add(0, 1) == 1
    end
  end
end
