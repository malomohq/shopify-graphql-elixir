defmodule Shopify.GraphQL.Request do
  alias Shopify.GraphQL.{ Config, Helpers, Operation, Response }

  @spec send(Operation.t(), Config.t(), map) :: Shopify.GraphQL.response_t()
  def send(operation, config, private \\ %{})

  def send(operation, %{ retry: false } = config, private) do
    do_send(operation, config, private)
  end

  def send(operation, config, private) do
    private = Map.put_new(private, :attempts, 0)

    attempt = Map.get(private, :attempts) + 1
    max_attempts = Keyword.get(config.retry_opts, :max_attempts, 3)

    result = do_send(operation, config, private)

    if retryable?(result) && max_attempts >= attempt do
      send(operation, config, %{ private | attempts: attempt })
    else
      result
    end
  end

  defp do_send(operation, config, private) do
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
        { :error, Response.new(response, config, private) }
      { :ok, %{ status_code: status_code } = response}
        when status_code >= 200 ->
        { :ok, Response.new(response, config, private) }
      otherwise ->
        otherwise
    end
  end

  defp retryable?(result) do
    case result do
      { :ok, _response } ->
        false
      { :error, %Response{ status_code: status_code } } when status_code >= 500 ->
        true
      { :error, %Response{} } ->
        false
      _otherwise ->
        true
    end
  end
end
