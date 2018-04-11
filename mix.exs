defmodule Hatoba.MixProject do
  use Mix.Project

  def project do
    [
      app: :hatoba,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Hatoba, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:porcelain, "~> 2.0"},
      {:httpoison, "~> 1.0"},
      {:poison, "~> 3.1"},
      {:mock, "~> 0.3.0", only: :test}
    ]
  end
end
