defmodule ElixirInAction.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_in_action,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      xref: [exclude: [UUID]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {App, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true}
      {:httpoison, "~> 2.0"},
      {:jason, "~> 1.4"},
      {:tzdata, "~> 1.1"},
      {:sage, "~> 0.6.3"},
      {:ecto, "~> 3.9.5"},
      {:floki, "~> 0.34.2"},
      {:yaml_elixir, "~> 2.9.0"},
      {:pubsub, "~> 1.1.2"},
      {:nimble_parsec, "~> 1.3.1"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:csv, "~> 3.0"},
      {:decimal, "~> 2.0"},
      {:uuid, "~> 1.1"},
      {:timex, "~> 3.0"},
      {:elixir_map_to_xml, "~> 0.1.0"},
      {:elixir_xml_to_map, "~> 2.0"},
      {:kino, "~> 0.8.0"},
      {:kino_vega_lite, "~> 0.1.7"}
    ]
  end
end
