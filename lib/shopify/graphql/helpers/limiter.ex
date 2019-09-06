defmodule Shopify.GraphQL.Helpers.Limiter do
  @spec time_to_restore(
          atom | number,
          Shopify.GraphQL.Limiter.ThrottleState.t()
        ) :: non_neg_integer
  def time_to_restore(:half, throttle_state) do
    max = throttle_state.maximum_available

    time_to_restore(max / 2, throttle_state)
  end

  def time_to_restore(:max, throttle_state) do
    max = throttle_state.maximum_available

    time_to_restore(max, throttle_state)
  end

  def time_to_restore(to, throttle_state) do
    available = throttle_state.currently_available
    rate = throttle_state.restore_rate

    if available > to do
      0
    else
      ceil((to - available) / rate) * 1_000
    end
  end
end
