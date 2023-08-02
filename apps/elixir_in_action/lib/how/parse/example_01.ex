defmodule How.Parse.Example01 do
  import NimbleParsec

  date =
    integer(4)
    |> ignore(string("-"))
    |> integer(2)
    |> ignore(string("-"))
    |> integer(2)

  time =
    integer(2)
    |> ignore(string(":"))
    |> integer(2)
    |> ignore(string(":"))
    |> integer(2)
    |> optional(string("Z"))

  defparsec(:datetime, date |> ignore(string("T")) |> concat(time), debug: true)
end
