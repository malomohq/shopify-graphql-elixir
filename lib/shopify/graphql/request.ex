defmodule Shopify.GraphQL.Request do
  alias Shopify.GraphQL.{ Helpers }

  @spec send(binary | Shopify.GraphQL.Operation.t(), map) ::
        { :ok, Shopify.GraphQL.Response.t() } | { :error, any }
  def send(operation_or_query, config \\ %{})
  
  def send(query, config) when is_binary(query) do
    operation = %Shopify.GraphQL.Operation{ query: query }

    Shopify.GraphQL.Request.send(operation, config)
  end

  def send(operation, config) do
    config = Shopify.GraphQL.Config.new(config)

    query = operation.query
    variables = operation.variables

    http_client_opts = config.http_client_opts

    body = Helpers.JSON.encode(%{ query: query, variables: variables }, config)
    headers = Helpers.Headers.new(config)
    method = :post
    url = Helpers.URL.new(config)

    result =
      config.http_client.request(
        method,
        url,
        headers,
        body,
        http_client_opts
      )

    case result do
      { :ok, %{ status_code: status_code } = response}
        when status_code >= 400 ->
        { :error, Shopify.GraphQL.Response.new(response, config) }
      { :ok, %{ status_code: status_code } = response}
        when status_code >= 200 ->
          { :ok, Shopify.GraphQL.Response.new(response, config) }
      otherwise ->
        otherwise
    end
  end
end
