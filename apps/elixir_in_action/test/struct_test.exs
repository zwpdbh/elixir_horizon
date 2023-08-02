defmodule StructTest do

  defmodule FractionTest do
    use ExUnit.Case
    alias Struct.Fraction
    test "create fraction" do
      assert (Fraction.new(1, 10) |> Fraction.value) == 1/10
      assert Fraction.new(1, 0) == {:error, "b could not be zero"}
    end
  end
end
