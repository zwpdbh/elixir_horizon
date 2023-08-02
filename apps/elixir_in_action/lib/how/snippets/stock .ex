defmodule How.Snippets.Stock do
  def compute_increase(csv_file) do
    csv_file
    |> File.stream!()
    |> CSV.decode(separator: ?,, headers: true)
    |> Stream.filter(&filter_valid_recod(&1))
    |> Stream.map(&standarize_record/1)
    |> Enum.reduce(%{}, &get_each_stock_range/2)
    |> Stream.filter(&filter_range_value/1)
    |> Stream.map(&compute_range_value/1)
    |> Stream.filter(&filter_non_negative_value/1)
    |> Enum.sort_by(fn %{increase_value: v} -> v end, :desc)
    |> List.first()
    |> print_result
  end

  defp filter_valid_recod(
         {:ok,
          %{
            "Value" => value_str,
            "Name" => _name,
            "Date" => _data,
            "notes" => _note,
            "Change" => _change
          }} = x
       ) do
    value_str
    |> Float.parse()
    |> case do
      {_value, ""} -> x
      _ -> nil
    end
  end

  defp filter_valid_recod(_) do
    nil
  end

  defp standarize_record(
         {:ok,
          %{
            "Value" => value_str,
            "Name" => name,
            "Date" => date_str,
            "notes" => notes,
            "Change" => change
          }}
       ) do
    {value, ""} = Float.parse(value_str)
    date = convert_str_to_date(date_str)
    %{value: value, name: name, date: date, change: change, notes: notes}
  end

  defp convert_str_to_date(str) do
    str
    |> String.split("-")
    |> Enum.map(&String.to_integer/1)
    |> (fn [year, month, day] -> Date.new!(year, month, day) end).()
  end

  defp get_each_stock_range(
         %{value: value, name: name, date: date, change: _change, notes: _notes},
         %{} = acc
       ) do
    case Map.fetch(acc, name) do
      {:ok, current_range} ->
        updated_range = update_range(current_range, %{value: value, date: date})
        Map.put(acc, name, updated_range)

      :error ->
        Map.put_new(acc, name, {%{date: date, value: value}, %{date: date, value: value}})
    end
  end

  # Given a existing range which is a tuple, and a new value, update the range
  defp update_range(
         {%{date: first_date} = first_one, %{date: last_date} = last_one},
         %{date: date} = current_one
       ) do
    case {Date.compare(date, first_date), Date.compare(date, last_date)} do
      {:lt, _} ->
        {current_one, last_one}

      {_, :gt} ->
        {first_one, current_one}

      _ ->
        {first_one, last_one}
    end
  end

  # a range for a stock is like:
  # {"IQZ",
  #  {%{date: ~D[2015-07-08], value: 656.36},
  #   %{date: ~D[2015-10-08], value: 537.53}}}
  defp filter_range_value({_stock_name, {%{date: start_date}, %{date: end_date}}} = x) do
    case Date.compare(start_date, end_date) do
      :lt -> x
      _ -> nil
    end
  end

  defp compute_range_value({stock_name, {%{value: start_value}, %{value: end_value}}}) do
    %{
      stock: stock_name,
      increase_value: Decimal.sub(Decimal.from_float(end_value), Decimal.from_float(start_value))
    }
  end

  defp filter_non_negative_value(%{increase_value: value} = x) do
    case Decimal.compare(value, 0) do
      :gt -> x
      _ -> nil
    end
  end

  defp print_result(result) do
    case result do
      nil ->
        "nil"

      %{stock: stock, increase_value: value} ->
        "company: #{stock}, increase_value: #{value |> Decimal.round(6) |> Decimal.to_string()}"
    end
  end
end
