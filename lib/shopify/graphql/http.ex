defmodule Shopify.GraphQL.Http do
  alias Shopify.GraphQL.{ Request }

  @type response_t ::
          %{
            body: String.t(),
            headers: Shopify.GraphQL.http_headers_t(),
            status_code: Shopify.GraphQL.http_status_code_t()
          }

  @callback send(
              request :: Request.t(),
              opts :: any
            ) :: { :ok, response_t } | { :error, response_t | any }
end
