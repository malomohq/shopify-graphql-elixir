defmodule Shopify.GraphQL.LimiterTest do
  use ExUnit.Case, async: true

  alias Shopify.GraphQL.{ Config, Limiter }

  test "get_shop_name/1" do
    config = Config.new(%{ shop: "a-shop" })

    assert Limiter.get_shop_name(config) == "a-shop.myshopify.com"
  end

  test "starts", tags do
    assert { :ok, pid } = Limiter.start_link(name: process_name(tags))
    assert Process.alive?(pid)
  end

  #
  # private
  #

  defp process_name(tags) do
    line = Map.get(tags, :line)
    module = Map.get(tags, :module)

    Module.concat(["#{module}:#{line}"])
  end
end
