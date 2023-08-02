defmodule How.Parse.Example03Test do
  use ExUnit.Case
  alias How.Parse.Example03

  test "parse phone number with international_prefix" do
    {:ok,
     %Example03.PhoneNumber{
       area_code: "20",
       country_code: 31,
       subscriber_number: "4284105"
     }} = Example03.PhoneNumber.new("+31 20-42 84 105")
  end
end
