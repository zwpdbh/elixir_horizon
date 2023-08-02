defmodule How.Typespecs do
  defmodule LousyCalculatorV1 do
    @spec add(number, number) :: {number, String.t()}
    def add(x, y), do: {x + y, "You need a calculator to do that?!"}

    @spec multiply(number, number) :: {number, String.t()}
    def multiply(x, y), do: {x * y, "Jeez, come on!"}
  end

  defmodule LousyCalculatorV2 do
    @typedoc """
    Just a number followed by a string.
    """
    @type number_with_remark :: {number, String.t()}

    @spec add(number, number) :: number_with_remark
    def add(x, y), do: {x + y, "You need a calculator to do that?"}

    @spec multiply(number, number) :: number_with_remark
    def multiply(x, y), do: {x * y, "It is like addition on steroids."}
  end

  defmodule QuietCalculator do
    # Custom types defined through @type are exported and are available outside the module they’re defined in:
    # Here, we could see the "number_with_remark" is available.
    @spec add(number, number) :: number
    def add(x, y), do: make_quiet(LousyCalculatorV2.add(x, y))

    @spec make_quiet(LousyCalculatorV2.number_with_remark()) :: number
    defp make_quiet({num, _remark}), do: num
  end
end

defmodule How.Behaviours do
  # Think of behaviours like interfaces in object oriented languages like Java: a set of function signatures that a module has to implement.
  # If a module adopting a given behaviour doesn’t implement one of the callbacks required by that behaviour, a compile-time warning will be generated.
  # With @impl you can also make sure that you are implementing the correct callbacks from the given behaviour in an explicit manner.
  defmodule Parser do
    @doc """
    Parses a string.
    """
    @callback parse(String.t()) :: {:ok, term} | {:error, String.t()}

    @doc """
    Lists all supported file extensions.
    """
    @callback extensions() :: [String.t()]

    # Behaviours are frequently used with dynamic dispatching.
    # This function will be dispatched to the given implementation.
    # TBD: how to use this?
    def parse!(implementation, contents) do
      case implementation.parse(contents) do
        {:ok, data} -> data
        {:error, error} -> raise ArgumentError, "parsing error: #{error}"
      end
    end
  end

  defmodule JSONParser do
    @behaviour Parser

    @impl Parser
    # ... parse JSON
    def parse(str), do: {:ok, "some json " <> str}

    @impl Parser
    def extensions, do: ["json"]
  end

  defmodule YAMLParser do
    @behaviour Parser

    @impl Parser
    # ... parse YAML
    def parse(str), do: {:ok, "some yaml " <> str}

    @impl Parser
    def extensions, do: ["yml"]
  end
end
