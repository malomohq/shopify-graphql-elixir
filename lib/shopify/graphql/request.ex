defmodule Shopify.GraphQL.Request do
  alias Shopify.GraphQL.{ Config, Helpers, Operation, Response }

  @spec send(Operation.t(), Config.t()) :: Shopify.GraphQL.response_t()
  def send(operation, config) do
    query = operation.query
    variables = operation.variables

    http_client_opts = config.http_client_opts

    body = Helpers.JSON.encode(%{ query: query, variables: variables }, config)
    headers = Helpers.Headers.new(config)
    method = :post
    url = Helpers.URL.to_string(config)

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
        { :error, Response.new(response, config) }
      { :ok, %{ status_code: status_code } = response}
        when status_code >= 200 ->
        { :ok, Response.new(response, config) }
      otherwise ->
        otherwise
    end
  end
end
