defmodule Sparkline.Mixfile do
  use Mix.Project

  def project do
    [app: :sparkline,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  defp description do
    """
    Sparkline lets you create small inline ANSI charts of time series. It supports
    two modes: sparkline and chart. The former fits in one line, the latter spans
    multiple lines and has labels.
    """
  end

  defp deps do
    [{:timex, "~> 3.1"}]
  end

  defp package do
    [
      name: :sparkline,
      files: ["lib", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
      maintainers: ["Meltwater Group"],
      licences: ["MIT"],
      links: %{"GitHub" => "https://github.com/meltwater/sparkline"}
    ]
  end
end
