defmodule Shopify.GraphQL.Client do
  @moduledoc """
  Behaviour for implementing an HTTP client.
  """

  @type headers_t :: [{ String.t(), String.t() }]

  @type method_t :: :delete | :get | :post | :put

  @callback request(
              method :: method_t,
              url :: String.t(),
              headers :: headers_t,
              body :: binary,
              opts :: any
            ) :: { :ok, Shopify.GraphQL.Response.t() } | { :error, any }
end
