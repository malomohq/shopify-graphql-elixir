defmodule Shopify.GraphQL.Helpers.LimiterTest do
  use ExUnit.Case, async: true

  alias Shopify.GraphQL.{ Helpers, Limiter }

  test "time_to_restore/2" do
    throttle_state =
      %Limiter.ThrottleState{
        currently_available: 0,
        maximum_available: 10,
        restore_rate: 2
      }

    assert 3_000 == Helpers.Limiter.time_to_restore(:half, throttle_state)
    assert 5_000 == Helpers.Limiter.time_to_restore(:max, throttle_state)
    assert 1_000 == Helpers.Limiter.time_to_restore(2, throttle_state)
    assert 0_000 == Helpers.Limiter.time_to_restore(2, %{ throttle_state | currently_available: 20 })
  end
end
