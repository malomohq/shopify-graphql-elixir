defmodule Shopify.GraphQL.Limiter.ShopTest do
  use ExUnit.Case, async: true

  alias Shopify.GraphQL.{ Limiter }

  test "start_link/1", tags do
    assert { :ok, _pid } = Limiter.Shop.start_link(name: process_name(tags))
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
