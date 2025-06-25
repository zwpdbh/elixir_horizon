# This module shows the basic usage of spawn, send and receive.
defmodule How.Concurrency.Primitive.SpawnBasic do
  def greet do
    IO.puts("Hello")
  end

  def demo01 do
    # The spawn function kicks off a new process in general two ways
    # 1. run an anonymous function; 2. run a named function in a module.
    # Here, we use case 2.
    spawn(__MODULE__, :greet, [])
  end

  def demo02 do
    spawn(fn -> greet() end)
  end

  def hello do
    receive do
      {sender, msg} ->
        send(sender, {:ok, "Hellow, #{msg}"})
    end
  end

  def demo03 do
    pid = spawn(__MODULE__, :hello, [])
    send(pid, {self(), "World!"})

    receive do
      {:ok, message} ->
        IO.puts(message)
    after
      500 ->
        IO.puts("Time out from greeter.")
    end
  end

  def hello_v2() do
    receive do
      {sender, msg} ->
        send(sender, {:ok, "Hellow, #{msg}"})
    end

    hello_v2()
  end

  def demo04 do
    pid = spawn(__MODULE__, :hello_v2, [])
    send(pid, {self(), "World!"})

    receive do
      {:ok, message} ->
        IO.puts(message)
    after
      500 ->
        IO.puts("Time out from greeter.")
    end

    send(pid, {self(), "My Friend!"})

    receive do
      {:ok, message} ->
        IO.puts(message)
    after
      500 ->
        IO.puts("Time out from greeter.")
    end
  end
end

# This example is from: Chapter 15. Working with Multiple Processes • 204 (book: Programming Elixir >= 1.6)
# It shows the overhead of creating millions of process by measuring the time to create n processes sequencially.
defmodule How.Concurrency.Primitive.ProcessOverhead do
  def counter(next_pid) do
    receive do
      n ->
        send(next_pid, n + 1)
    end
  end

  def create_processes(n) do
    code_to_run = fn _, send_to ->
      spawn(__MODULE__, :counter, [send_to])
    end

    last = Enum.reduce(1..n, self(), code_to_run)
    send(last, 0)

    receive do
      final_awnser when is_integer(final_awnser) ->
        "Result is #{inspect(final_awnser)}"
    end
  end

  def run(n) do
    :timer.tc(__MODULE__, :create_processes, [n])
    |> IO.inspect()
  end
end

# Shows link two processes: one exit will send message to another.
# Linking joins the calling process and another process—each receives notifications about the other.
defmodule How.Concurrency.Primitive.LinkingTwoProcesses do
  import :timer, only: [sleep: 1]

  def sad_function do
    sleep(500)
    exit(:boom)
  end

  def run do
    Process.flag(:trap_exit, true)
    spawn_link(__MODULE__, :sad_function, [])

    receive do
      msg ->
        IO.puts("MESSAGE RECEIVED: #{inspect(msg)}")
    after
      1000 ->
        IO.puts("Nothing happended as far as I am concerned")
    end
  end
end

# Show a process create and monitor another process. It is different from link by this is one way direction notification.
defmodule How.Concurrency.Primitive.SpawnMonitor do
  import :timer, only: [sleep: 1]

  def sad_function do
    sleep(500)
    exit(:boom)
  end

  def run do
    res = spawn_monitor(__MODULE__, :sad_function, [])
    IO.puts(inspect(res))

    receive do
      msg ->
        IO.puts("Message received: #{inspect(msg)}")
    after
      1000 ->
        IO.puts("Nothing happended as far as I am concerned")
    end
  end
end

# Parllel Map
defmodule How.Concurrency.Primitive.Parallel do
  def pmap(collection, fun) do
    me = self()

    collection
    |> Enum.map(fn elem ->
      spawn_link(fn -> send(me, {self(), fun.(elem)}) end)
    end)
    |> Enum.map(fn _pid ->
      receive do
        # Without use of ^pid, we'd get back the results in random order.
        {_pid, result} ->
          result
      end
    end)
  end

  def run do
    pmap(1..100, &(&1 * &1))
  end
end

defmodule How.Concurrency.Primitive.Fib do
  defmodule Solver do
    def fib(scheduler) do
      send(scheduler, {:ready, self()})

      receive do
        {:fib, n, client} ->
          send(client, {:answer, n, fib_calc(n), self()})
          fib(scheduler)

        {:shutdown} ->
          exit(:normal)
      end
    end

    defp fib_calc(0), do: 0
    defp fib_calc(1), do: 1
    defp fib_calc(n), do: fib_calc(n - 1) + fib_calc(n - 2)
  end

  defmodule Scheduler do
    def run(num_processes, module, func, to_calculate) do
      1..num_processes
      |> Enum.map(fn _ -> spawn(module, func, [self()]) end)
      |> schedule_processes(to_calculate, [])
    end

    defp schedule_processes(processes, queue, results) do
      receive do
        {:ready, pid} when queue != [] ->
          [next | tail] = queue
          send(pid, {:fib, next, self()})
          schedule_processes(processes, tail, results)

        {:ready, pid} when queue == [] ->
          send(pid, {:shutdown})

          if length(processes) > 1 do
            schedule_processes(List.delete(processes, pid), queue, results)
          else
            Enum.sort(results, fn {n1, _}, {n2, _} -> n1 <= n2 end)
          end

        {:answer, number, result, _pid} ->
          schedule_processes(processes, queue, [{number, result} | results])
      end
    end
  end

  def run do
    to_process = List.duplicate(37, 20)

    Enum.each(1..10, fn num_processes ->
      {time, result} =
        :timer.tc(
          Scheduler,
          :run,
          [num_processes, Solver, :fib, to_process]
        )

      if num_processes == 1 do
        IO.puts(inspect(result))
        IO.puts("\n # time (s)")
      end

      :io.format("~2B ~.2f~n", [num_processes, time / 1_000_000.0])
    end)
  end
end

# Other examples
defmodule How.Concurrency.Primitive.SpawnExample do
  def run_query(query_def) do
    Process.sleep(2000)
    "#{query_def} result"
  end

  def get_result_fn do
    fn ->
      receive do
        {:query_result, result} ->
          current_time = DateTime.utc_now()
          IO.puts("Receive message #{current_time}")
          result
      end
    end
  end

  def async_query(query_def) do
    spawn(fn ->
      IO.puts(run_query(query_def))
    end)
  end

  def async_query_v2(query_def) do
    caller = self()

    spawn(fn ->
      send(caller, {:query_result, run_query(query_def)})
    end)
  end

  def demo01 do
    Enum.each(1..5, &async_query("query #{&1}"))
  end

  def demo02 do
    # Instead of printing to the screen, make the lambda send the query result to the caller
    # a simple parallel map that can be used to process a larger amount of work in parallel
    # then collect the results into a list
    # The parallel comes from we spawn multiple processes for each query
    1..5
    |> Enum.map(&async_query_v2("query #{&1}"))
    |> Enum.map(fn _ -> get_result_fn().() end)
  end
end
