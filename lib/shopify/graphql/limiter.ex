defmodule Shopify.GraphQL.Limiter do
  @moduledoc """
  Manage request throttling by the Shopify GraphQL API.

  Shopify rate limits requests made to it's GraphQL API based on the complexity
  of a query. If the query cost exceeds the available cost limit the API will
  throttle the request and prevent the query from executing.

  If you'd like to know more about Shopify rate limiting please see
  [GraphQL Admin API rate limits](https://help.shopify.com/en/api/graphql-admin-api/graphql-admin-api-rate-limits).
  """

  use DynamicSupervisor

  alias Shopify.GraphQL.{ Helpers }

  #
  # client
  #

  @doc """
  Returns the shop name from `Shopify.GraphQL.Config`.
  """
  @spec get_shop_name(Shopify.GraphQL.Config.t()) :: String.t()
  def get_shop_name(config) do
    config
    |> Helpers.URL.to_uri()
    |> Map.get(:host)
  end

  @doc """
  Starts a `Shopify.GraphQL.Limiter` supervision tree and links it to the
  current process.
  """
  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: get_name(opts))
  end

  #
  # callbacks
  #

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  #
  # private
  #

  defp get_name(opts) do
    Keyword.get(opts, :name, __MODULE__)
  end
end
