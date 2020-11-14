defmodule Shopify.GraphQL.Config do
  defstruct access_token: nil,
            endpoint: "/graphql.json",
            http_client: Shopify.GraphQL.Http.Hackney,
            http_client_opts: [],
            http_headers: [],
            http_host: "myshopify.com",
            http_path: "/admin/api",
            http_port: nil,
            http_protocol: "https",
            json_codec: Jason,
            limiter: false,
            limiter_opts: [],
            retry: false,
            retry_opts: [],
            shop: nil,
            version: nil

  @type t ::
          %__MODULE__{
            access_token: String.t(),
            endpoint: String.t(),
            http_client: module,
            http_client_opts: any,
            http_headers: Shopify.GraphQL.http_headers_t(),
            http_host: String.t(),
            http_path: String.t(),
            http_port: pos_integer,
            http_protocol: String.t(),
            json_codec: module,
            limiter: Shopify.GraphQL.Limiter.name_t(),
            limiter_opts: Keyword.t(),
            retry: boolean,
            retry_opts: Keyword.t(),
            shop: String.t(),
            version: String.t()
          }

  @spec new(Keyword.t()) :: t
  def new(overrides) do
    Map.merge(%__MODULE__{}, Enum.into(overrides, %{}))
  end
end
