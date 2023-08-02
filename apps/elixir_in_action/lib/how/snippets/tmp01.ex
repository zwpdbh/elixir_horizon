defmodule How.Snippets.Tmp01 do
  def add(a, b) do
    a + b
  end

  def take(n, lst)  do
    take_aux(n, lst, [], 0)
  end

  defp take_aux(n, lst, acc, c) when n >= 0 do
    case lst do
      [ head | tail ] when c <= n-1 ->
        take_aux(n, tail, [head | acc], c + 1)
      _ ->
        Enum.reverse(acc)
    end
  end

  def drop(n, lst) do
    drop_aux(n, lst, 0)
  end

  defp drop_aux(n, lst, c) do
    case lst do
      [_|rest] when c <= n - 1 ->
        drop_aux(n, rest, c+1)
      rest ->
        rest
    end
  end

end
