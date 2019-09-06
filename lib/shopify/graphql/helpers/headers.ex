defmodule Shopify.GraphQL.Helpers.Headers do
  @moduledoc false

  alias Shopify.GraphQL.{ Config }

  @spec new(Config.t()) :: Shopify.GraphQL.http_headers_t()
  def new(config) do
    []
    ++ [{ "content-type", "application/json" }]
    ++ [{ "x-shopify-access-token", config.access_token }]
    ++ config.headers
  end
end
