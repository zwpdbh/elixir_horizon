defmodule Puzzle.SlideWindow.SubString do
  # longgest sub string

  def solve(s) do
    s
    |> String.graphemes()
    |> solve_aux([], [])
  end

  def solve_aux(l, acc, solution) do
    case {l, acc} do
      {[x | tail], []} ->
        solve_aux(tail, [x], [x])
      {[x | tail], acc} ->
        updated_acc = update(x, acc)
        # IO.inspect({updated_acc, solution})
        if length(updated_acc) >= length(solution) do
          solve_aux(tail, updated_acc, updated_acc)
        else
          solve_aux(tail, updated_acc, solution)
        end
      {[], _acc} ->
        solution
        |> Enum.reverse()
        |> Enum.join("")
    end
  end

  def update(c, acc) do
    acc
    |> Enum.take_while(fn each -> each != c end)
    |> then(fn x -> [c | x] end)
  end

  # simulate the case when give an accumulated list of s
  # we meet a new one. How to update
  def update(c) do
    "abcdef"
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.take_while(fn each -> each != c end)
    |> then(fn x -> [c | x] end)
  end

end
