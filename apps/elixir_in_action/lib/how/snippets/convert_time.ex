defmodule How.Snippets.ConvertTime do
  @moduledoc """
  Shows how to get a time from string and convert it into a different timezone

  As we have noted in the previous section, by default Elixir does not have any timezone data. To solve this issue, we need to install and set up the tzdata package. After installing it, you should globally configure Elixir to use Tzdata as timezone database:

  config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
  ref: https://github.com/lau/tzdata
  """
  def demo() do
    {:ok, x, _} = DateTime.from_iso8601("2023-06-25T17:34:34.0952444Z")

    {:ok, x_in_shanghai} = x |> DateTime.shift_zone("Asia/Shanghai")

    x_in_shanghai
  end

  def get_datetime_in_shanghai_from_str(nil) do
    nil
  end

  def get_datetime_in_shanghai_from_str(str) do
    {:ok, x, _} = DateTime.from_iso8601(str)
    {:ok, x_in_shanghai} = x |> DateTime.shift_zone("Asia/Shanghai")

    x_in_shanghai
  end

  # NativeTime is useful as start point to build DateTime with timezone.
  def build_datetime_with_timezone(native_time, timezone \\ "Asia/Shanghai") do
    DateTime.from_naive!(native_time, timezone)
  end

  def build_native_time(date_str, time_str) do
    [yyyy_str, mm_str, dd_str] = date_str |> String.split("-")
    {yyyy, _} = Integer.parse(yyyy_str)
    {mm, _} = Integer.parse(mm_str)
    {dd, _} = Integer.parse(dd_str)

    [hour_str, min_str, second_str] = time_str |> String.split(":")
    {hour, _} = Integer.parse(hour_str)
    {min, _} = Integer.parse(min_str)
    {second, _} = Integer.parse(second_str)

    NaiveDateTime.new!(yyyy, mm, dd, hour, min, second)
  end

  def build_native_time_from_date(date_str) do
    build_native_time(date_str, "18:00:00")
  end

  def get_yesterday_native_time(time_str \\ "18:00:00") do
    date_str = "#{Date.utc_today() |> Date.add(-1)}"
    NaiveDateTime.from_iso8601!(date_str <> " " <> time_str)
  end
end
