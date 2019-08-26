defmodule Shopify.GraphQL.Helpers.URLTest do
  use ExUnit.Case, async: true

  describe "new/1" do
    test "with shop" do
      shop = Shopify.GraphQL.Generators.gen_string()

      config = Shopify.GraphQL.Config.new(%{ shop: shop })

      assert Shopify.GraphQL.Helpers.URL.new(config) == "#{config.protocol}://#{shop}.#{config.host}/#{config.path}/#{config.version}/#{config.endpoint}"
    end

    test "without shop" do
      config = Shopify.GraphQL.Config.new()

      assert Shopify.GraphQL.Helpers.URL.new(config) == "#{config.protocol}://#{config.host}/#{config.path}/#{config.version}/#{config.endpoint}"
    end
  end
end
