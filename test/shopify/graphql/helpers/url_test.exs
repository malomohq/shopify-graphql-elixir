defmodule Shopify.GraphQL.Helpers.URLTest do
  use ExUnit.Case, async: true

  alias Shopify.GraphQL.{ Config, Helpers }

  describe "new/1" do
    test "with :shop" do
      config = Config.new(%{ shop: "a-shop" })

      assert Helpers.URL.new(config) == "#{config.protocol}://a-shop.#{config.host}/#{config.path}/#{config.version}/#{config.endpoint}"
    end

    test "without :shop" do
      config = Config.new()

      assert Helpers.URL.new(config) == "#{config.protocol}://#{config.host}/#{config.path}/#{config.version}/#{config.endpoint}"
    end
  end
end
