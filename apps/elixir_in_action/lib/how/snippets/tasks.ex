# Practise Task module for: https://hexdocs.pm/elixir/1.14.5/Task.html

defmodule How.Snippets.Tasks do
  # Tasks are processes meant to execute one particular action throughout their lifetime,
  # often with little or no communication with other processes.
  # The most common use case for tasks is to convert sequential code into concurrent code by computing a value asynchronously:

  def do_something() do
    Process.sleep(3000)
    IO.puts("Finished")
  end

  # Dynamically supervised tasks
  # The Task.Supervisor module allows developers to dynamically create multiple supervised tasks.
  def demo_supervised_task_v1() do
    {:ok, pid} = Task.Supervisor.start_link()
    task = Task.Supervisor.async(pid, &do_something/0)
    Task.await(task)
  end

  def demo_supervised_task_v2() do
    Supervisor.start_link(
      [
        {Task.Supervisor, name: MyApp.TaskSupervisor}
      ],
      strategy: :one_for_one
    )

    # Now, we could pass the name of the supervisor instead of the pid:
    Task.Supervisor.async(MyApp.TaskSupervisor, &do_something/0)
    |> Task.await()
  end

  def demo_supervised_task_v3(n) do
    {:ok, pid} = Task.Supervisor.start_link()

    # We could handle unexpected exception
    task_fun = fn arg ->
      # Function to execute in parallel
      Process.sleep(Enum.random(0..10) * 100)

      case {rem(arg, 2) == 0, rem(arg, 5) == 0} do
        {true, true} ->
          IO.puts("Task #{arg} oops")
          raise "oops exception!"

        {true, _} ->
          IO.puts("Task #{arg} failed")
          {:failed, arg}

        {_, true} ->
          IO.puts("Task #{arg} failed")
          {:failed, arg}

        {_, _} ->
          IO.puts("Task #{arg} completed")
          {:succeed, arg}
      end
    end

    Task.Supervisor.async_stream_nolink(pid, 1..20, task_fun,
      max_concurrency: n,
      timeout: 700,
      on_timeout: :kill_task,
      zip_input_on_exit: true
    )
    # If we don't provide [], the result will contain something like: [10, 8, 6, 4, 2 | {:ok, {:error, 1}}]
    |> Enum.reduce(%{}, fn result, acc ->
      case result do
        {:ok, {:succeed, n}} ->
          Map.update(acc, :succeed, [n], fn existing_ones -> [n | existing_ones] end)

        {:ok, {:failed, n}} ->
          Map.update(acc, :failed, [n], fn existing_ones -> [n | existing_ones] end)

        {:exit, {n, {%RuntimeError{message: exception_message}, _}}} ->
          Map.update(acc, :"#{exception_message}", [n], fn existing_ones ->
            [n | existing_ones]
          end)

        {:exit, {n, :timeout}} ->
          Map.update(acc, :timeout, [n], fn existing_ones -> [n | existing_ones] end)
      end
    end)
  end

  # Rely on supervised tasks as much as possible.
  # Using Task.Supervisor.start_child/2 allows you to start a fire-and-forget task that you don't care about its results or if it completes successfully or not.
  # Using Task.Supervisor.async/2 + Task.await/2 allows you to execute tasks concurrently and retrieve its result. If the task fails, the caller will also fail.
  # Using Task.Supervisor.async_nolink/2 + Task.yield/2 + Task.shutdown/2 allows you to execute tasks concurrently and retrieve their results
  # or the reason they failed within a given time frame. If the task fails, the caller won't fail. You will receive the error reason either on yield or shutdown.
end
