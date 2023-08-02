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
