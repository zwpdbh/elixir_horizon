# Protocols are a mechanism to achieve polymorphism in Elixir when you want behaviour to vary depending on the data type.
# Different from using pattern matching and guard clauses.
# We mainly use protocol to extend other people's original behaviour for as many data types as we need.
# Dispatching on a protocol is available to any data type that has implemented the protocol and a protocol can be implemented by anyone, at any time.

defmodule UtilityUsingPatternMatching do
  def type(value) when is_binary(value), do: "string"
  def type(value) when is_integer(value), do: "integer"
  # ... other implementations ...
  # If we own this code, we could keep adding the feature to meet the requirement.
end

# Use protocol to add protocol defined function on any types (default or custom one)
defprotocol Utility do
  @spec type(t) :: String.t()
  def type(value)
end

defimpl Utility, for: BitString do
  def type(_value), do: "string"
end

defimpl Utility, for: Integer do
  def type(_value), do: "integer"
end

defmodule How.Protocols.User do
  defstruct first_name: "",
            last_name: ""
end

defimpl Utility, for: How.Protocols.User do
  def type(_value), do: "User"
end

# iex(6)> Utility.type(%How.Protocols.User{})
# "User"

# Implementing Any to derive the protocol
# Deriving
# TBD: https://elixir-lang.org/getting-started/protocols.html
