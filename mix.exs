defmodule Realm.MixProject do
  use Mix.Project

  def project do
    [
      app: :realm,
      version: "0.1.0",
      name: "Realm",
      description: description(),
      source_url: "https://github.com/shikanime/realm",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  defp description do
    """
    Work with type classes with algebraic or category-theoretic.
    """
  end

  defp docs do
    [
      main: "Realm",
      extras: ["README.md"]
    ]
  end

  defp deps do
    [
      {:quark, "~> 2.3"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.7", only: :dev, runtime: false},
      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false}
    ]
  end
end
