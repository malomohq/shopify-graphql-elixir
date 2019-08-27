defmodule Shopify.GraphQL.Helpers.HeadersTest do
  use ExUnit.Case, async: true

  alias Shopify.GraphQL.{ Config, Helpers }

  test "new/1" do
    access_token = "yaay"

    additional_header = { "x-graphql-cost-include-fields", true }

    headers = Helpers.Headers.new(Config.new(%{ access_token: access_token, headers: [additional_header] }))

    assert Enum.member?(headers, { "content-type", "application/json" })
    assert Enum.member?(headers, { "x-shopify-access-token", access_token })
    assert Enum.member?(headers, additional_header)
  end
end
