defmodule Shopify.GraphQL do
  @type http_headers_t :: [{ String.t(), String.t() }]

  @type http_method_t :: :delete | :get | :post | :put

  @doc """
  Send a GraphQL operation to Shopify.
  """
  @spec send(Shopify.GraphQL.Operation.t(), map) ::
        { :ok, Shopify.GraphQL.Response.t() } | { :error, any }
  defdelegate send(operation, config \\ %{}), to: Shopify.GraphQL.Request
end
