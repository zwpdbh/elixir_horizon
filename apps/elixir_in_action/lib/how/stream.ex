# https://inquisitivedeveloper.com/lwm-elixir-44/
# https://hexdocs.pm/elixir/1.14.3/Stream.html
defmodule How.Stream do
  def demo01 do
    # The stream will be lazy evaluated. Here, it is not evaluated.
    [1, 2, 3] |> Stream.map(fn x -> x * 2 end)

    # Its result is like: Stream<[enum: [1, 2, 3], funs: [#Function<48.50989570/1 in Stream.map/2>]]>
  end

  def demo02 do
    [9, -1, "foo", 25, 49]
    |> Stream.filter(&(is_number(&1) and &1 > 0))
    |> Stream.map(&{&1, :math.sqrt(&1)})
    |> Stream.with_index()
    |> Enum.each(fn {{input, result}, index} ->
      IO.puts("#{index + 1}. sqrt(#{input}) = #{result}")
    end)
  end

  # Some ways to create streams
  def demo_unfold do
    # https://hexdocs.pm/elixir/1.14.3/Stream.html#unfold/2
    Stream.unfold(10, fn acc ->
      case acc do
        0 ->
          nil

        n ->
          {n, n - 1}
      end
    end)
    |> Enum.to_list()
  end

  def demo_cycle do
    Stream.cycle([1, 2, 3, 5, 7])
    |> Enum.take(100)
  end

  def demo_resource do
    Stream.resource(
      fn -> File.open!(File.cwd!() <> "/mix.exs") end,
      fn file ->
        case IO.read(file, :line) do
          data when is_binary(data) -> {[data], file}
          _ -> {:halt, file}
        end
      end,
      fn file -> File.close(file) end
    )
    |> Enum.to_list()
  end

  def demo_chunk_every do
    Stream.chunk_every(1..6, 2) |> Enum.to_list() |> IO.inspect()
    Stream.chunk_every(1..6, 3, 2, :discard) |> Enum.to_list() |> IO.inspect()
    Stream.chunk_every(1..6, 4, 2, Stream.cycle([0])) |> Enum.to_list()
  end

  def demo_transform do
    my_stream_map = fn enum, func ->
      Stream.transform(enum, 1111, fn item, acc -> {[func.(item) + acc], acc} end)
    end

    my_stream_map.(1..10, &(&1 * 10)) |> Enum.to_list()
  end

  def stream_data_to_an_output_file do
    Stream.cycle([1, 3, 4, 12, 11])
    |> Stream.take(100)
    |> Stream.map(&(inspect(&1) <> "\n"))
    # The path "elixir_programming/elixir_horizon/tmp" has to be exit! The file output.txt will be created if not exist.
    |> Stream.into(File.stream!(File.cwd!() <> "/tmp/output.txt"))
    |> Stream.run()
  end

  def stream_into_two_places_with_back_presure do
    # TBD: one producer stream, two consumer stream
    # https://elixirforum.com/t/cloning-a-stream-one-stream-two-consumers/39947/3
  end

  def stream_parse_large_xml do
    # TBD: stream parse large xml file without loading entire file into memory
    # From: https://betterprogramming.pub/stream-output-when-parsing-big-xml-with-elixir-92baff37e607
  end
end
