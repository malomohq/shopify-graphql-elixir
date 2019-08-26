defmodule Shopify.GraphQL.MixProject do
  use Mix.Project

  def project do
    [
      app: :shopify_graphql,
      version: "1.0.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [plt_add_apps: [:hackney]],
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      { :hackney,  "~> 1.15", optional: true },
      { :jason,    "~> 1.1",  optional: true },
      # dev
      { :dialyxir, "~> 1.0-rc", only: :dev, runtime: false },
      { :ex_doc,   "> 0.0.0",   only: :dev, runtime: false }
    ]
  end

  defp package do
    %{
      description: "Elixir client for the GraphQL admin API",
      maintainers: ["Anthony Smith"],
      licenses: ["MIT"],
      links: %{
        GitHub: "https://github.com/malomohq/shopify-graphql"
      }
    }
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_env), do: ["lib"]
end
