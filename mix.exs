defmodule Shopify.GraphQL.MixProject do
  use Mix.Project

  def project do
    [
      app: :shopify_graphql,
      version: "1.4.1",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [plt_add_apps: [:gen_stage, :hackney]],
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
      { :gen_stage, ">= 0.14.0 and < 2.0.0", optional: true },
      { :hackney,   "~> 1.15", optional: true },
      { :jason,     "~> 1.1",  optional: true },
      # dev
      { :dialyxir, "~> 1.0-rc", only: :dev, runtime: false },
      { :ex_doc,   "> 0.0.0",   only: :dev, runtime: false },
      # test
      { :bypass, "~> 1.0", only: :test }
    ]
  end

  defp package do
    %{
      description: "Elixir client for the Shopify GraphQL admin API",
      maintainers: ["Anthony Smith"],
      licenses: ["MIT"],
      links: %{
        GitHub: "https://github.com/malomohq/shopify-graphql-elixir",
        "Made by Malomo - Post-purchase experiences that customers love": "https://gomalomo.com"
      }
    }
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_env), do: ["lib"]
end
