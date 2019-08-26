defmodule Shopify.GraphQL.Helpers.HeadersTest do
  use ExUnit.Case, async: true

  alias Shopify.GraphQL.{ Config, Helpers }

  test "new/1" do
    assert [
      { "content-type", "application/json" },
      { "x-shopify-access-token", "yaay" }
    ] = Helpers.Headers.new(Config.new(%{ access_token: "yaay" }))
  end
end
