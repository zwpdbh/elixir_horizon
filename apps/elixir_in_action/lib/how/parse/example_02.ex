defmodule How.Parse.Example02 do
  import NimbleParsec

  # Examples from: https://blog.appsignal.com/2022/10/18/parser-combinators-in-elixir-taming-semi-structured-text.html

  # one "0"
  trunk_prefix = string("0") |> ignore()

  # one "-" or " "
  separator =
    choice([string("-"), string(" ")])
    |> ignore()

  # one digit
  digit = utf8_string([?0..?9], 1)

  # area_code is a two digits
  area_code =
    times(digit, 2)
    |> reduce({Enum, :join, [""]})
    |> unwrap_and_tag(:area_code)

  # one digit or " " repeat at least once, but ignore " " in the result
  subscriber_number =
    choice([digit, string(" ") |> ignore()])
    |> times(min: 1)
    |> reduce({Enum, :join, [""]})
    |> unwrap_and_tag(:subscriber_number)

  dutch_phone_number =
    trunk_prefix
    |> concat(area_code)
    |> concat(separator)
    |> concat(subscriber_number)
    |> eos()

  defparsec(:parse, dutch_phone_number)
end

defmodule How.Parse.Example02.PhoneNumber do
  alias How.Parse.Example02

  defstruct [
    :country_code,
    :area_code,
    :subscriber_number
  ]

  def new(str) when is_binary(str) do
    case Example02.parse(str) do
      {:ok, results, "", _, _, _} -> {:ok, struct!(__MODULE__, results)}
      {:error, reason, _rest, _, _, _} -> {:error, reason}
    end
  end
end
