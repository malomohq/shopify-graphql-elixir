defmodule Shopify.GraphQL do
  alias Shopify.GraphQL.{ Operation, Request, Response }

  @type http_headers_t ::
          [{ String.t(), String.t() }]

  @type http_method_t ::
          :delete | :get | :head | :patch | :post | :put

  @type http_response_t ::
          { :ok, Response.t() } | { :error, Response.t() | any }

  @type http_status_code_t ::
          pos_integer

  @spec send(String.t() | Operation.t(), Keyword.t()) :: http_response_t
  def send(query, config) when is_binary(query) do
    __MODULE__.send(%Operation{ query: query }, config)
  end

  def send(operation, config) do
    operation
    |> Request.new(config)
    |> Request.send(config)
  end
end
