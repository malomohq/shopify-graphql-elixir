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
  Returns the identifier used to name `Shopify.GraphQL.Limiter.Shop` processes.

  The identifier is the shop host name (e.g. `some-shop.myshopify.com`) and
  can be extracted from a `Shopify.GraphQL.Config` struct.
  """
  @spec get_shop_id(Shopify.GraphQL.Config.t()) :: String.t()
  def get_shop_id(config) do
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

  @doc """
  Starts a `Shopify.GraphQL.Limiter.Shop` supervision tree.
  """
  @spec start_shop(atom, String.t()) :: DynamicSupervisor.on_start_child()
  def start_shop(server \\ __MODULE__, shop_id) do
    spec = { __MODULE__.Shop, name: get_shop_name(server, shop_id) }

    DynamicSupervisor.start_child(server, spec)
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

  defp get_shop_name(server, shop_id) do
    Module.concat([server, "Shop:#{shop_id}"])
  end
end
