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

  #
  # client
  #

  @spec send(atom, Shopify.GraphQL.Operation.t(), map) ::
        { :ok, Shopify.GraphQL.Response.t() } | { :error, any }
  def send(_server, _operation, _config) do
    { :error, :not_implemented }
  end

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: get_name(opts))
  end

  #
  # callbacks
  #

  @impl true
  def init(opts) do
    opts = opts ++ [strategy: :one_for_one]

    DynamicSupervisor.init(opts)
  end

  #
  # private
  #

  defp get_name(opts) do
    Keyword.get(opts, :name, __MODULE__)
  end
end
