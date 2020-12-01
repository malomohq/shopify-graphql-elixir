if Code.ensure_loaded?(GenStage) do
  defmodule Shopify.GraphQL.Limiter.ThrottleState do
    alias Shopify.GraphQL.{ Response }

    @type t ::
            %__MODULE__{
              currently_available: integer,
              maximum_available: integer,
              restore_rate: integer
            }

    defstruct [:currently_available, :maximum_available, :restore_rate]

    @doc """
    Returns a `Shopify.GraphQL.Limiter.ThrottleStatus` struct from a
    `Shopify.GraphQL.Response` struct.
    """
    @spec new(Response.t()) :: t
    def new(response) do
      throttle_status =
        response
        |> Map.get(:body)
        |> Map.get("extensions")
        |> Map.get("cost")
        |> Map.get("throttleStatus")

      currently_available = Map.get(throttle_status, "currentlyAvailable")

      maximum_available = Map.get(throttle_status, "maximumAvailable")

      restore_rate = Map.get(throttle_status, "restoreRate")

      %__MODULE__{}
      |> Map.put(:currently_available, currently_available)
      |> Map.put(:maximum_available, maximum_available)
      |> Map.put(:restore_rate, restore_rate)
    end

    @spec throttle_for(t, :half | :max | non_neg_integer) :: non_neg_integer
    def throttle_for(throttle_state, :half) do
      throttle_for(throttle_state, round(throttle_state.maximum_available / 2))
    end

    def throttle_for(throttle_state, :max) do
      throttle_for(throttle_state, throttle_state.maximum_available)
    end

    def throttle_for(throttle_state, to) do
      available = throttle_state.currently_available

      if available > to do
        0
      else
        ceil((to - available) / throttle_state.restore_rate) * 1_000
      end
    end
  end
end
