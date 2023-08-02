defmodule How.Concurrency.GenericServer.KeyValueStoreGenServerExample do
  defmodule KeyValueStore do
    use GenServer

    def start do
      GenServer.start(KeyValueStore, nil)
    end

    def put(pid, key, value) do
      GenServer.cast(pid, {:put, key, value})
    end

    def get(pid, key) do
      GenServer.call(pid, {:get, key})
    end

    @impl GenServer
    def init(_) do
      {:ok, %{}}
    end

    # we need to define a handle_info/2 function to process custom plain message.
    @impl GenServer
    def handle_info(:cleanup, state) do
      IO.puts("performing cleanup...")
      {:noreply, state}
    end

    # It is very good practise to specify the @impl attribute for every callback function
    @impl GenServer
    def handle_cast({:put, key, value}, state) do
      {:noreply, Map.put(state, key, value)}
    end

    @impl GenServer
    def handle_call({:get, key}, _, state) do
      {:reply, Map.get(state, key), state}
    end
  end

  defmodule Demos do
    def demo() do
      {:ok, pid} = KeyValueStore.start()
      KeyValueStore.put(pid, :some_key, :some_value)
      KeyValueStore.get(pid, :some_key)
    end
  end
end
