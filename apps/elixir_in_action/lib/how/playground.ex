defmodule How.Playground do
  defmodule PatternMatching do
    def run() do
      run({:ok, "step01"})
    end

    def run({:ok, "step01"}) do
      run({:ok, "step02"})
    end

    def run({:ok, "step02"}) do
      {:ok, "finished"}
    end
  end
end

defmodule Person do
  defstruct name: "unknow", age: 0, email: nil
end

defmodule MyApi do
  def do_something(%Person{name: "wei", age: 0}) do
    {:error, "no email"}
  end

  def do_something(%Person{email: email}) do
    {:ok, email}
  end

  def test_email() do
    with {:ok, email} <- do_something(%Person{name: "wei"}) do
      {:ok!, email}
    else
      e -> e
    end
  end
end
