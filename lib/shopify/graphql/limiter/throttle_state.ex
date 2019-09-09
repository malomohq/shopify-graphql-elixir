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
  @spec from_response(Response.t()) :: t
  def from_response(response) do
    throttle_status =
      response
      |> Map.get(:body)
      |> Map.get("extensions")
      |> Map.get("cost")
      |> Map.get("throttleStatus")

    currently_available = Map.get(throttle_status, "currentlyAvailable")
    maximum_available = Map.get(throttle_status, "maximumAvailable")
    restore_rate = Map.get(throttle_status, "restoreRate")

    %__MODULE__{
      currently_available: currently_available,
      maximum_available: maximum_available,
      restore_rate: restore_rate
    }
  end
end
