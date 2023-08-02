defmodule How.Concurrency.Primitive.Node do
  defmodule NamingNodes do
    def how_to_name_node_v1 do
      # iex --name wei@zw.local
    end

    def how_to_name_node_v2 do
      # iex --sname node01
    end

    def how_to_connect do
      # On window01
      # $ iex --sname node01
      # Interactive Elixir (1.13.4) - press Ctrl+C to exit (type h() ENTER for help)

      # On window02
      # iex(node02@zw)2> Node.list
      # []
      # iex(node02@zw)3> Node.connect :"node01@zw"
      # true
      # iex(node02@zw)4> Node.list
      # [:node01@zw]
    end

    def how_to_run_a_process_on_other_node do
      # iex(node02@zw)5> Node.spawn(:"node01@zw", fn -> IO.inspect(Node.self) end)
      # :node01@zw
      # PID<11626.116.0>
    end

    def how_to_secure_erlang_system do
      # On window01
      # $ iex --sname node01 --cookie the-secret-cookie
      # Interactive Elixir (1.13.4) - press Ctrl+C to exit (type h() ENTER for help)
      # iex(node01@zw)1>
      # 21:03:26.308 [error] ** Connection attempt from node :node02@zw rejected. Invalid challenge reply. **

      # On window02
      # wei@zw MINGW64 /d/code/elixir-programming/elixir_horizon (dev/from-home)
      # $ iex --sname node02 --cookie the-wrong-cookie
      # Interactive Elixir (1.13.4) - press Ctrl+C to exit (type h() ENTER for help)
      # iex(node02@zw)1> Node.connect :"node01@zw"
      # false

      # We have to use the same cookie to connect
      # $ iex --sname node02 --cookie the-secret-cookie
      # Interactive Elixir (1.13.4) - press Ctrl+C to exit (type h() ENTER for help)
      # iex(node02@zw)1> Node.connect :"node01@zw"
      # true
    end
  end

  defmodule NamingProcess do
    # The general rule is to register your process names when your application starts.
    # Examples from Naming Your Processes • 225
    defmodule Ticker do
      @interval 2000
      @name :ticker

      # Common pattern: We have a moduel that is responsible both for
      # 1. spwaning a process
      def start do
        pid = spawn(__MODULE__, :generator, [[]])
        # That's how we register a global name.
        :global.register_name(@name, pid)
      end

      # 2. providing the external interface to that process.
      def register(client_pid) do
        send(:global.whereis_name(@name), {:register, client_pid})
      end

      def generator(clients) do
        receive do
          {:register, pid} ->
            IO.puts("registering #{inspect(pid)}")
            generator([pid | clients])
        after
          @interval ->
            IO.puts("tick")

            Enum.each(clients, fn client ->
              send(client, {:tick})
            end)

            generator(clients)
        end
      end
    end

    defmodule TickerClient do
      def start do
        pid = spawn(__MODULE__, :receiver, [])
        # Use Ticker's API to register the process from spawn
        # It seems the pattern is module just contain a group of pure functions.
        # When we need to maintain a state, we spawn a process in which
        # we use recursive loop to keep tracking state and receive messages send to it
        Ticker.register(pid)
      end

      def receiver do
        receive do
          {:tick} ->
            IO.puts("tock in client")
        end

        receiver()
      end
    end
  end
end
