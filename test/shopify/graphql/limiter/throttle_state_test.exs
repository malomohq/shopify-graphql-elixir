defmodule Shopify.GraphQL.Limiter.ThrottleStateTest do
  use ExUnit.Case, async: true

  alias Shopify.GraphQL.{ Limiter }

  test "from_response/1" do
    response =
      %Shopify.GraphQL.Response{
        body: %{
          "extensions" => %{
            "cost" => %{
              "requestedQueryCost" => 101,
              "actualQueryCost" => 46,
              "throttleStatus" => %{
                "maximumAvailable" => 1_000,
                "currentlyAvailable" => 954,
                "restoreRate" => 50
              }
            }
          }
        }
      }

    assert %Limiter.ThrottleState{
             currently_available: 954,
             maximum_available: 1_000,
             restore_rate: 50
            } = Limiter.ThrottleState.from_response(response)
  end
end
