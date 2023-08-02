# Task.async creates a separate process that runs the given function.
defmodule How.Concurrency.Primitive.TaskDemo do
  defmodule Fib do
    def of(0), do: 0
    def of(1), do: 1
    def of(n), do: of(n - 1) + of(n - 2)
  end

  defmodule TaskExample01 do
    def run_v1 do
      IO.puts("Start the task")
      # worker is the task descriptor
      worker = Task.async(fn -> Fib.of(20) end)

      IO.puts("Do something else")
      IO.puts("Wait for the task")
      # pass task descriptor when await
      result = Task.await(worker)

      IO.puts("The result is #{result}")
    end

    def run_v2 do
      worker = Task.async(Fib, :of, [20])
      result = Task.await(worker)
      IO.puts("The result is #{result}")
    end
  end

  defmodule TaskExample02 do
    @moduledoc """
    This module shows how to run multiple tasks with a degree of parallel.
    A task could be succeed, failed or timeout.
    All results are collected
    """
    def run_with_parallel_degree(n) do
      task_fun = fn arg ->
        # Function to execute in parallel
        Process.sleep(Enum.random(0..10) * 100)

        if rem(arg, 2) == 0 do
          IO.puts("Task #{arg} completed")
          {:succeed, arg}
        else
          IO.puts("Task #{arg} failed")
          {:failed, arg}
        end
      end

      Task.async_stream(1..20, task_fun, max_concurrency: n, timeout: 700, on_timeout: :kill_task, zip_input_on_exit: true)
      # If we don't provide [], the result will contain something like: [10, 8, 6, 4, 2 | {:ok, {:error, 1}}]
      |> Enum.reduce(%{}, fn result, acc ->
        case result do
          {:ok, {:succeed, n}} ->
            Map.update(acc, :succeed, [n], fn existing_ones -> [n | existing_ones] end)
          {:ok, {:failed, n}} ->
            Map.update(acc, :failed, [n], fn existing_ones -> [n | existing_ones] end)
          {:exit, reason} ->
            Map.update(acc, :timeout, [reason], fn existing_ones -> [reason | existing_ones] end)
        end
      end)
    end
  end
end

# An agent is a background process that maintains state.
# The initial state is set by a function we pass in when we start the agent.
defmodule How.Concurrency.Primitive.Agent do
  defmodule SimpleAgent do
    @moduledoc """
    This module shows how to use Agent as a simple solution to hold mutation
    """
    def run do
      {:ok, count} = Agent.start(fn -> 0 end)
      Agent.get(count, & &1)
      Agent.update(count, &(&1 + 1))
      Agent.update(count, &(&1 + 1))
      Agent.get(count, & &1)
    end
  end

  defmodule Frequency do
    @moduledoc """
    This module shows how to use Agent as a simple solution to hold mutation.
    Agent.start_link will start an agent linking it to the current process, helpful if you’re using an agent as part of a supervision tree.
    See: https://elixircasts.io/intro-to-agents
    """
    # This is all initialized with the start_link function, which, presumably, is invoked during application initialization.
    def start_link do
      Agent.start_link(fn -> %{} end, name: __MODULE__)
    end

    def add_word(word) do
      Agent.update(__MODULE__, fn map ->
        Map.update(map, word, 1, &(&1 + 1))
      end)
    end

    def count_for_word(word) do
      Agent.get(__MODULE__, fn map -> map[word] end)
    end

    def words do
      Agent.get(__MODULE__, fn map -> Map.keys(map) end)
    end

    def run do
      start_link()
      add_word("brave")
      add_word("here")
      add_word("brave")
      count_for_word("brave")
      GenServer.stop(__MODULE__)
    end
  end

  defmodule FibAgent do
    def start_link do
      Agent.start_link(fn -> %{0 => 0, 1 => 1} end)
    end

    def fib(pid, n) when n >= 0 do
      Agent.get_and_update(pid, &do_fib(&1, n))
    end

    defp do_fib(cache, n) do
      case cache[n] do
        nil ->
          {n_1, cache} = do_fib(cache, n - 1)
          result = n_1 + cache[n - 2]
          {result, Map.put(cache, n, result)}

        cached_value ->
          {cached_value, cache}
      end
    end

    def run do
      {:ok, agent} = start_link()
      IO.puts(fib(agent, 2000))
    end
  end
end
