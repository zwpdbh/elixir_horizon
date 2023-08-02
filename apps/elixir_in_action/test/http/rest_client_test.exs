defmodule Http.RestClientTest do
  use ExUnit.Case

  alias Http.RestClient

  test "create headers from lists" do
    header_options =
      RestClient.add_header("key1", 111)
      |> RestClient.add_header("key2", 222)
      |> RestClient.add_header("key3", 333)
      |> RestClient.add_header("key2", 444)

    assert header_options == %{
             "key1" => 111,
             "key2" => 444,
             "key3" => 333
           }
  end

  test "header map to header list" do
    header_list =
      RestClient.add_header("key1", 111)
      |> RestClient.add_header("key2", 222)
      |> RestClient.add_header("key3", 333)
      |> RestClient.add_header("key2", 444)
      |> RestClient.map_to_tuple_list()

    assert header_list == [{"key1", 111}, {"key2", 444}, {"key3", 333}]
  end

  test "body to binary" do
    body =
      RestClient.add_body("app_key", "some key")
      |> RestClient.add_body("param", %{"page" => 10, "book" => "hyperion"})
      |> RestClient.encode_map_to_json()

    assert body == "{\"app_key\":\"some key\",\"param\":{\"book\":\"hyperion\",\"page\":10}}"
  end
end
