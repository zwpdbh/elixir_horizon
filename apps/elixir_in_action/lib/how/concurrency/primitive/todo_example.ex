defmodule How.Concurrency.Primitive.TodoExample do
  defmodule TodoServer do
    alias How.Concurrency.Primitive.TodoExample.TodoList
    # Here we explicitly specify the TodoList as a dependency.
    # In the loop, we update the state which is a struct of TodoList
    def start do
      spawn(fn -> loop(TodoList.new()) end)
    end

    # TODO:: add other interface and server process
    defp loop(todo_list) do
      new_todo_list =
        receive do
          message -> process_message(todo_list, message)
        end

      loop(new_todo_list)
    end

    # for each request we want to support, we have to
    # 1) add a dedicated clause in the process_message/2 function
    # 2) add a corresponding interface function
    defp process_message(todo_list, {:add_entry, new_entry}) do
      TodoList.add_entry(todo_list, new_entry)
    end

    defp process_message(todo_list, {:entries, caller, date}) do
      send(caller, {:todo_entries, TodoList.entries(todo_list, date)})
      todo_list
    end

    # Interface
    def add_entry(todo_server, new_entry) do
      send(todo_server, {:add_entry, new_entry})
    end

    def entries(todo_server, date) do
      send(todo_server, {:entries, self(), date})

      receive do
        {:todo_entries, entries} -> entries
      after
        5000 -> {:error, :timeout}
      end
    end
  end

  defmodule TodoList do
    defstruct auto_id: 1, entries: %{}

    # Create entries from a list of entry
    def new() do
      %TodoList{}
    end

    def new(entries \\ []) do
      Enum.reduce(
        entries,
        %TodoList{},
        fn entry, todo_list_acc ->
          add_entry(todo_list_acc, entry)
        end
      )
    end

    def add_entry(todo_list, entry) do
      entry = Map.put(entry, :id, todo_list.auto_id)

      new_entries =
        todo_list
        |> Map.put(todo_list.auto_id, entry)

      %TodoList{todo_list | entries: new_entries, auto_id: todo_list.auto_id + 1}
    end

    def entries(todo_list, date) do
      todo_list.entries
      |> Stream.filter(fn {_, entry} -> entry.date == date end)
      |> Enum.map(fn {_, entry} -> entry end)
    end

    def update_entry(todo_list, %{} = new_entry) do
      update_entry(todo_list, new_entry.id, fn _ -> new_entry end)
    end

    def update_entry(todo_list, entry_id, updater_fn) do
      case Map.fetch(todo_list.entries, entry_id) do
        :error ->
          todo_list

        {:ok, old_entry} ->
          # Here, we are using nested pattern matching.
          # we make sure the updater lambda be a map.
          # ^var means matching on the value of the variable.
          # so, we also make sure the id doesn't change in the lambda.
          old_entry_id = old_entry.id
          new_entry = %{id: ^old_entry_id} = updater_fn.(old_entry)

          new_entries = Map.put(todo_list.entries, new_entry.id, new_entry)
          %TodoList{todo_list | entries: new_entries}
      end
    end
  end
end
