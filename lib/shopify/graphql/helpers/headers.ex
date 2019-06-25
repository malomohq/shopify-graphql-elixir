defmodule Shopify.GraphQL.Helpers.Headers do
  @moduledoc false

  @spec new(Shopify.GraphQL.Config.t()) :: Shopify.GraphQL.http_headers_t()
  def new(config) do
    [
      { "content-type", "application/json" },
      { "x-shopify-access-token", config.access_token }
    ]
  end
end
