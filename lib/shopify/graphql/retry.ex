defmodule Shopify.GraphQL.Retry do
  alias Shopify.GraphQL.{ Config, Request }

  @callback wait_for(request :: Request.t(), config :: Config.t()) :: non_neg_integer
end
