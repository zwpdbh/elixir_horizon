# Structs (#18): https://inquisitivedeveloper.com/lwm-elixir-18/
defmodule Struct.Fraction do
  alias Struct.Fraction
  defstruct a: nil, b: nil

  def new(a, b) when b != 0 do
    %Fraction{a: a, b: b}
  end

  def new(_, b) when b == 0 do
    {:error, "b could not be zero"}
  end

  def value(%Fraction{a: a, b: b}) do
    a / b
  end

  def add(%Fraction{a: a1, b: b1}, %Fraction{a: a2, b: b2}) do
    new(
      a1 * b2 + a2 * b1,
      b2 * b1
    )
  end
end
