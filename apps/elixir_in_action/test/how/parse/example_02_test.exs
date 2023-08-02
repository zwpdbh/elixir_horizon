defmodule How.Parse.Example02Test do
  use ExUnit.Case
  alias How.Parse.Example02

  test "case 01" do
    Example02.parse("020-42 84 105")
  end

  test "case 02" do
    {:ok,
     %Example02.PhoneNumber{
       area_code: "20",
       country_code: nil,
       subscriber_number: "4284105"
     }} = Example02.PhoneNumber.new("020-42 84 105")
  end
end
