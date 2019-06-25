defmodule Shopify.GraphQL.MixProject do
  use Mix.Project

  def project do
    [
      app: :shopify_graphql,
      version: "0.0.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
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
      { :ex_doc, "> 0.0.0", only: :dev, runtime: false }
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
end
