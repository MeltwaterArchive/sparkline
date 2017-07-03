# Sparkline

Sparkline lets you create small inline ANSI charts of time series. It supports
two modes: sparkline and chart. The former fits in one line, the latter spans
multiple lines and has labels.

      iex> Sparkline.sparkline [1,2,3,4,5,6,7,8]
      "▁▂▃▄▅▆▇█"


## Installation

Sparkline is [available in Hex](https://hex.pm/packages/sparkline) and can be installed
by adding `sparkline` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:sparkline, "~> 0.1.0"}]
end
```

Documentation can be found at [https://hexdocs.pm/sparkline](https://hexdocs.pm/sparkline).

