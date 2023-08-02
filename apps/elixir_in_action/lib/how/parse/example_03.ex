# Follow from Example02
# See: https://blog.appsignal.com/2022/11/15/parser-combinators-in-elixir-a-deeper-dive.html
defmodule How.Parse.Example03.Helper do
  # Helper contains pure functions
  import NimbleParsec

  @doc """
  Parses a single digit.
  """
  def digit(combinator \\ empty()) do
    combinator
    |> utf8_string([?0..?9], 1)
  end

  @doc """
  Parses `count` digits.

  For example, `digits(3)` would parse 3 digits.
  """
  def digits(combinator \\ empty(), count) do
    combinator
    |> duplicate(digit(), count)
    |> reduce({Enum, :join, [""]})
  end

  @doc """
  Parses a phone number area code.

  Since phone number area codes can only be 2 or 3 digits in length,
  only `2` and `3` are valid values for the `length` parameter.
  """
  def area_code(combinator \\ empty(), length) when length in [2, 3] do
    combinator
    |> digits(length)
  end

  def subscriber_number(combinator \\ empty(), length) when length in [6, 7] do
    combinator
    |> digit()
    |> times(combinator |> string(" ") |> optional() |> ignore() |> digit(), length - 1)
    |> ignore(string(" ") |> optional())
    |> reduce({Enum, :join, [""]})
  end

  def local_number(combinator \\ empty(), area_code_length, subscriber_number_length) do
    separator = choice([string("-"), string(" ")])

    combinator
    |> area_code(area_code_length)
    |> unwrap_and_tag(:area_code)
    |> concat(ignore(separator))
    |> concat(subscriber_number_length |> subscriber_number |> unwrap_and_tag(:subscriber_number))
  end
end

defmodule How.Parse.Example03 do
  alias How.Parse.Example03.Helper
  import NimbleParsec

  # one "0"
  trunk_prefix = string("0")

  international_prefix =
    ignore(string("+"))
    |> Helper.digits(2)
    |> ignore(string(" "))
    |> map({String, :to_integer, []})
    |> unwrap_and_tag(:country_code)

  local_portion =
    choice([
      Helper.local_number(2, 7),
      Helper.local_number(3, 6)
    ])

  dutch_phone_number =
    choice([international_prefix, ignore(trunk_prefix)])
    |> concat(local_portion)
    |> eos()

  # The parser module couldn't contain functions therefore we move helper functions into a seperate module as Helper
  defparsec(:parse, dutch_phone_number)

  # During development, we could always test a seperate helper as parser.
  # For example in iex:  Example03.subscriber_number("65 23 125")
  defparsec(:subscriber_number, Helper.subscriber_number(7))
end

defmodule How.Parse.Example03.PhoneNumber do
  alias How.Parse.Example03

  defstruct [
    :country_code,
    :area_code,
    :subscriber_number
  ]

  def new(str) when is_binary(str) do
    case Example03.parse(str) do
      {:ok, results, "", _, _, _} -> {:ok, struct!(__MODULE__, results)}
      {:error, reason, _rest, _, _, _} -> {:error, reason}
    end
  end
end
