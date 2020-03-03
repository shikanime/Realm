defmodule Realm.MixProject do
  use Mix.Project

  def project do
    [
      app: :realm,
      version: "0.1.1",
      name: "Realm",
      description: description(),
      package: package(),
      source_url: "https://github.com/Shikanime/Realm",
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

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE", ".formatter.exs"],
      maintainers: ["Shikanime Deva"],
      licenses: ["MIT"],
      links: %{
        Documentation: "https://hexdocs.pm/realm",
        GitHub: "https://github.com/Shikanime/Realm"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
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
