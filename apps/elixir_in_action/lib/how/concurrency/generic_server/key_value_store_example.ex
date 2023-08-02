defmodule How.Concurrency.GenericServer.KeyValueStoreExample do
  # This example shows us how GenServer works in general.
  defmodule ServerProcess do
    def start(callback_module) do
      # Comparing this with How.Concurrency.Primitive.TodoExample.TodoServer
      # We pass callback_module and its loop over its internal state instead of
      # passing the client module's state to avoid dependency issue.
      spawn(fn ->
        initial_state = callback_module.init()
        loop(callback_module, initial_state)
      end)
    end
    # A *server process* is a beam process that use recurive call (loop) to handle different messages.
    # Which module has loop to maintain some state, which one is server process.
    defp loop(callback_module, current_state) do
      receive do
        {:call, request, caller} ->
          {response, new_state} = callback_module.handle_call(request, current_state)

          send(caller, {:response, response})
          loop(callback_module, new_state)

        {:cast, request} ->
          new_state = callback_module.handle_cast(request, current_state)

          loop(callback_module, new_state)
      end
    end

    # this got called from client to invoke call (synchronous) message
    def call(server_pid, request) do
      send(server_pid, {:call, request, self()})

      receive do
        {:response, response} -> response
      end
    end

    # this got called from client to invoke cast (asynchronous) message
    def cast(server_pid, request) do
      send(server_pid, {:cast, request})
    end
  end

  # Client module: which module passed in server process as call_back module, which one is client process.
  # A key/value store implementation as callback_module
  defmodule KeyValueStore do
    def init do
      %{}
    end

    # handle_call will be invoked from ServerProcess's loop, inside receive
    def handle_call({:put, key, value}, state) do
      {:ok, Map.put(state, key, value)}
    end

    def handle_call({:get, key}, state) do
      {Map.get(state, key), state}
    end

    def handle_cast({:put, key, value}, state) do
      Map.put(state, key, value)
    end

    # Helper functions used by user such that we hide the ServerProcess's abstraction call/2 from user.
    def put(pid, key, value) do
      ServerProcess.cast(pid, {:put, key, value})
    end

    def get(pid, key) do
      ServerProcess.call(pid, {:get, key})
    end

    def start do
      ServerProcess.start(KeyValueStore)
    end
  end

  defmodule Demos do
    def demo() do
      pid = KeyValueStore.start()
      KeyValueStore.put(pid, :some_key, :some_async_value)
      KeyValueStore.get(pid, :some_key)
    end
  end
end
