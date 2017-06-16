defmodule Sparkline do
  @moduledoc """
  Sparkline lets you create small inline ANSI charts of time series. It supports two
  modes: sparkline and chart. The former fits in one line, the latter spans
  multiple lines and has labels.
  """

  @doc ~S"""
  Get an inline sparkline.

  ## Examples

      iex> Sparkline.sparkline [1,2,3,4,5,6,7,8]
      "▁▂▃▄▅▆▇█"

      iex> Sparkline.sparkline [100, 200, 300]
      "▁▅█"

      iex> Sparkline.sparkline [-100, 0, 100]
      "▁▅█"

      iex> Sparkline.sparkline [-100, 0, 100], spark_bars: [".",":","|"]
      ".:|"

      iex> [
      ...>   %{data: 1},
      ...>   %{data: 2},
      ...>   %{data: 3},
      ...>   %{data: 4},
      ...>   %{data: 5},
      ...>   %{data: 6},
      ...>   %{data: 7},
      ...>   %{data: 8}
      ...> ] |> Enum.map(&(&1[:data])) |> Sparkline.sparkline
      "▁▂▃▄▅▆▇█"
  """
  def sparkline(data, options \\ []) do
    opts   = Keyword.merge(default_chart_options(), options)
    values = opts[:values].(data) |> Enum.map(&ensure_float/1)
    bars   = opts[:spark_bars]

    {min, max} = Enum.min_max values
    step  = (max - min) / (length(bars) - 1)
    steps = seq min, max - step, step

    bars_with_index = [steps, bars] |> Enum.zip
    for point <- data do
      case Enum.find bars_with_index, fn {x, _} -> x >= point end do
        {_, b} ->
          b
        nil ->
          bars |> List.last
      end
    end
    |> Enum.join
  end

  @doc ~S"""
  Get an ASCII chart for a time series.
  """
  def chart(data, options \\ []) do
    opts = Keyword.merge(default_chart_options(), options)
    x_labels = opts[:x_labels].(data) |> Enum.map(&(ensure_length(&1, opts[:bar_width] * 2)))
    values   = opts[:values].(data) |> Enum.map(&ensure_float/1)

    {ylabel_numbers, ylabel_strings, ylabel_width} = ylabels(values, opts)

    lines = [ylabel_numbers, ylabel_strings]
    |> Enum.zip
    |> Enum.map(&(chart_line(values, &1, opts)))
    |> Enum.reverse

    x_axis = ""
    |> prepend_by(opts[:bar_width] * length(values) + 1, "-")
    |> prepend_by(ylabel_width + 1)
    x_labels_odd = x_labels
    |> Enum.take_every(2)
    |> Enum.join
    |> prepend_by(ylabel_width + 1)

    x_labels_even = x_labels
    |> Enum.drop_every(2)
    |> Enum.join
    |> prepend_by(ylabel_width + opts[:bar_width] + 1)

    lines ++ [x_axis, x_labels_odd, x_labels_even]
    |> Enum.join("\n")
  end

  @doc ~S"""
  Convert a string ISO timestamp to a short label.
  """
  def get_time_label(iso_timestamp_string, granularity \\ :day) do
    timestamp = Timex.parse! iso_timestamp_string, "{ISO:Extended}"
    case granularity do
      :year ->
        Timex.format! timestamp, "%y", :strftime
      :month ->
        Timex.format! timestamp, "%m", :strftime
      :day ->
        timestamp |> Timex.weekday |> Timex.day_shortname |> String.slice(0, 2)
      :hour ->
        Timex.format! timestamp, "%H", :strftime
      :minute ->
        Timex.format! timestamp, "%M", :strftime
      :second ->
        Timex.format! timestamp, "%S", :strftime
      _ ->
        ""
    end
  end

  defp default_chart_options() do
    [
      height: 10,
      bar: "█",
      spark_bars: ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"],
      start_at_zero: false,
      bar_width: 2,
      x_labels: fn data -> (0..length(data)-1) |> Enum.map(&ensure_binary/1) end,
      y_labels: &format_ylabel/1,
      values: &(&1)
    ]
  end


  defp chart_line(data, {ylimit, ylabel}, opts) do
    ylabel <> "|" <> (
      data
      |> Enum.map(fn (count) -> if count >= ylimit, do: "#{opts[:bar]}", else: " " end)
      |> Enum.map(&(ensure_length(&1, opts[:bar_width])))
      |> Enum.join
    )
  end

  defp ylabels(data, options) do
    {min, max} = if options[:start_at_zero] and Enum.min(data) >= 0 do
      {0.0, Enum.max(data)}
    else
      Enum.min_max data
    end

    ylabel_numbers = if (max - min) >= options[:height] do
      seq min, max, (max - min) / options[:height]
    else
      seq min, max
    end

    ylabel_width = ylabel_numbers
    |> Enum.map(options[:y_labels])
    |> Enum.max_by(&String.length/1)
    |> String.length

    ylabel_strings = ylabel_numbers
    |> Enum.map(options[:y_labels])
    |> Enum.map(fn (s) -> String.pad_leading(s, ylabel_width) end)
    {ylabel_numbers, ylabel_strings, ylabel_width}
  end

  defp format_ylabel(num) do
    num
    |> Float.round(2)
    |> Float.to_string
  end

  defp floor(float) do
    float
    |> Float.floor
    |> round
  end

  defp seq(start, stop, step \\ 1) do
    case cmp step, 0.0 do
      :eq ->
        []

      :gt ->
        if start > stop do
          []
        else
          [start] ++ seq(start+step, stop, step)
        end
      :lt ->
        if start > stop do
          []
        else
          [start] ++ seq(start+step, stop, step)
        end
    end
  end

  defp cmp(left, right) do
    if left == right do
      :eq
    else
      if left < right do
        :lt
      else
        :gt
      end
    end
  end

  def prepend_by(string, number_of_chars, char \\ " ") do
    String.pad_leading("", number_of_chars, char) <> string
  end

  defp ensure_binary(s) when is_binary(s), do: s
  defp ensure_binary(i) when is_integer(i), do: Integer.to_string(i)

  defp ensure_length(s, length \\ 4)
  defp ensure_length(s, length) when is_binary(s) do
    s
    |> String.pad_trailing(length, " ")
    |> String.slice(0, length)
  end

  defp ensure_length(s, length) when is_integer(s) do
    s |> Integer.to_string |> ensure_length(length)
  end

  defp ensure_float(num) when is_float(num), do: num
  defp ensure_float(num) when is_integer(num), do: num * 1.0
end
