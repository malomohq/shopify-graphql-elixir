defmodule Shopify.GraphQL.Helpers.JSONTest do
  use ExUnit.Case, async: true

  alias Shopify.GraphQL.{ Config, Helpers }

  setup do
    %{ config: Config.new() }
  end

  test "decode/2", %{ config: config } do
    assert Helpers.JSON.decode("{\"ok\":true}", config) == %{ "ok" => true }
    assert Helpers.JSON.decode("{ yikes }", config) == %{}
  end

  test "encode/2", %{ config: config } do
    assert Helpers.JSON.encode(%{ ok: true }, config) == "{\"ok\":true}"
    assert Helpers.JSON.encode({ "yikes" }, config) == ""
  end
end
