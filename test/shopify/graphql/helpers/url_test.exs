defmodule Shopify.GraphQL.Helpers.URLTest do
  use ExUnit.Case, async: true

  alias Shopify.GraphQL.{ Config, Helpers }

  describe "to_string/1" do
    test "with :shop" do
      config = Config.new(%{ shop: "a-shop" })

      assert Helpers.URL.to_string(config) == "#{config.protocol}://a-shop.#{config.host}/#{config.path}/#{config.version}/#{config.endpoint}"
    end

    test "without :shop" do
      config = Config.new()

      assert Helpers.URL.to_string(config) == "#{config.protocol}://#{config.host}/#{config.path}/#{config.version}/#{config.endpoint}"
    end
  end

  describe "to_uri/1" do
    test "with :shop" do
      shop = "a-shop"

      config = Config.new(%{ shop: shop })

      host = "#{shop}.#{config.host}"
      path = "/#{config.path}/#{config.version}/#{config.endpoint}"
      scheme = config.protocol

      assert %URI{ host: ^host, path: ^path, scheme: ^scheme } = Helpers.URL.to_uri(config)
    end

    test "without :shop" do
      config = Config.new()

      host = "#{config.host}"
      path = "/#{config.path}/#{config.version}/#{config.endpoint}"
      scheme = config.protocol

      assert %URI{ host: ^host, path: ^path, scheme: ^scheme } = Helpers.URL.to_uri(config)
    end
  end
end
