defmodule Realm.MixProject do
  use Mix.Project

  def project do
    [
      app: :realm,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp deps do
    [
      {:quark, "~> 2.3"},
      {:quark, "~> 2.3"}
      {:dialyxir, "~> 1.0.0-rc.7", only: :dev, runtime: false},
      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false}
    ]
  end
end
