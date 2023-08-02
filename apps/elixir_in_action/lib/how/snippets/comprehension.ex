defmodule How.Snippets.Comprehension do
  def demo01() do
    for x <- [1, 2, 3], y <- [1, 2, 3], do: {x, y, x * y}
  end

  # Use "into" option to specify what to collect
  def demo02() do
    for x <- 1..9, y <- 1..9, into: %{} do
      {{x, y}, x * y}
    end
  end

  def demo03() do
    for x <- 1..3, y <- 1..3, into: [] do
      [[x, y, x * y]]
    end
  end
end
