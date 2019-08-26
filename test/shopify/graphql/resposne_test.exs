defmodule Shopify.GraphQL.ResponseTest do
  use ExUnit.Case, async: true

  alias Shopify.GraphQL.{ Config, Response }

  test "new/2" do
    config = Config.new()

    headers = [{ "content-type", "application/json" }]
    status_code = 200

    assert (
      %Response {
        body: %{ "ok" => true },
        headers: ^headers,
        status_code: ^status_code
      } = Response.new(%{ body: "{\"ok\":true}", headers: headers, status_code: status_code }, config)
    )
  end
end
