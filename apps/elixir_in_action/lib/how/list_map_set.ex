defmodule How.ListMapSet do
  def keywork_list() do
    errors = [
      bio:
        {"should be at least %{count} character(s)",
         [count: 2, validation: :length, kind: :min, type: :string]},
      name: {"can't be blank", [validation: :required]},
      email: {"can't be blank", [validation: :required]}
    ]

    errors[:bio]
  end

  def list_to_map do
    1..10
    |> Enum.map(fn x -> {x, x * x} end)
    |> Enum.into(%{})
  end

  def list_to_set do
    [1, 2, 3, 3, 1, 3]
    |> Enum.into(MapSet.new())
  end

  def list_remove_duplication do
    [1, 2, 3, 2, 1, 4]
    |> Enum.uniq_by(fn x -> x end)
  end

  def map_to_list do
    m =
      1..5
      |> Enum.map(fn x -> {x, 3 * x} end)
      |> Enum.into(%{})

    Map.to_list(m)
  end
end

defmodule How.NestedUpdate do
  def demo_update_map01 do
    # This is too complex
    my_map = %{
      foo: %{
        bar: %{
          baz: "my value"
        }
      }
    }

    new_bar_map =
      my_map
      |> Map.get(:foo)
      |> Map.get(:bar)
      |> Map.put(:baz, "new value")

    new_foo_map =
      my_map
      |> Map.get(:foo)
      |> Map.put(:bar, new_bar_map)

    Map.put(my_map, :foo, new_foo_map)
  end

  def demo_update_map02 do
    # Use put_in to update
    my_map = %{
      foo: %{
        bar: %{
          baz: "my value"
        }
      }
    }

    # use get_in to retrieve
    IO.puts(get_in(my_map, [:foo, :bar, :baz]))
    put_in(my_map, [:foo, :bar, :baz], "new value")
  end

  def demo_update_map03 do
    # update_in with function
    # Here, we could update value by applying a function
    my_map = %{
      bob: %{
        age: 36
      }
    }

    update_in(my_map, [:bob, :age], &(&1 + 1))
  end

  def demo_update_map04 do
    # put_in + access to create missing keys!
    # Put/update deep inside nested maps (and auto-create intermediate keys)
    # comes from https://elixirforum.com/t/put-update-deep-inside-nested-maps-and-auto-create-intermediate-keys/7993
    # => %{a: %{b: %{c: 42}}}

    put_in(%{a: %{}}, Enum.map([:a, :b, :c], &Access.key(&1, %{})), 42)
  end

  def demo_update_map05 do
    put_in(%{"a" => %{}}, Enum.map(["a", "b", "c"], &Access.key(&1, %{})), 42)
    # put_in(map01, Enum.map(["a", "b", "c"], &Access.key(&1, %{})), 100)
  end

  def demo_update_list01 do
    my_list = [foo: [bar: [baz: "my value"]]]

    put_in(my_list[:foo][:bar][:baz], "new value")
  end

  def demo_update_nested_map do
    my_parsed_json = %{"some" => %{"deeply" => %{"nested" => %{"key" => 1}}}}
    update_in(my_parsed_json["some"]["deeply"]["nested"]["key"], &(&1 + 1))
  end
end
