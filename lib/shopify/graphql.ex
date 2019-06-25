defmodule Shopify.GraphQL do
  @type http_headers_t :: [{ String.t(), String.t() }]

  @type http_method_t :: :delete | :get | :post | :put

  defdelegate send(operation, config \\ %{}), to: Shopify.GraphQL.Request
end
