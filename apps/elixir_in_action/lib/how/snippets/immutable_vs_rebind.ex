defmodule How.Snippets.ImmutableVsRebind do
  @moduledoc """
  Does rebind break the immutable of a variable in Elixir?
  See: https://stackoverflow.com/questions/29967086/are-elixir-variables-really-immutable

  The answer is no.
  Erlang and obviously Elixir that is built on top of it, embraces immutability. They simply don’t allow values in a certain memory location to change. Never Until the variable gets garbage collected or is out of scope.
  """
end
