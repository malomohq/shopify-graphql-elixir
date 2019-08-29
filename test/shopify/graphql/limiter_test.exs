defmodule Shopify.GraphQL.LimiterTest do
  use ExUnit.Case, async: true

  alias Shopify.GraphQL.{ Config, Limiter }

  test "get_shop_id/1" do
    config = Config.new(%{ shop: "a-shop" })

    assert Limiter.get_shop_id(config) == "a-shop.myshopify.com"
  end

  test "start_link/1", tags do
    assert { :ok, _pid } = Limiter.start_link(name: process_name(tags))
  end

  test "start_shop/2", tags do
    limiter = process_name(tags)

    Limiter.start_link(name: limiter)

    assert { :ok, _pid } = Limiter.start_shop(limiter, "a-shop.myshopify.com")
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
