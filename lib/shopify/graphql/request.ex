defmodule Shopify.GraphQL.Request do
  alias Shopify.GraphQL.{ Config, Helpers, Operation, Response }

  defstruct [
    body: nil,
    config: nil,
    headers: [],
    method: :post,
    private: %{},
    url: nil
  ]

  @type t ::
          %__MODULE__{
            body: String.t(),
            config: Config.t(),
            headers: Shopify.GraphQL.http_headers_t(),
            method: Shopify.GraphQL.http_method_t(),
            private: map,
            url: String.t()
          }

  @spec new(Operation.t(), Config.t()) :: t
  def new(operation, config) do
    url = Helpers.Url.to_string(config)

    headers = []
    headers = headers ++ [{ "content-type", "application/json" }]
    headers = headers ++ [{ "x-shopify-access-token", config.access_token }]
    headers = headers ++ config.http_headers

    body = Map.new()
    body = Map.put(body, :query, operation.query)
    body = Map.put(body, :variables, operation.variables)
    body = config.json_codec.encode!(body)

    %__MODULE__{}
    |> Map.put(:body, body)
    |> Map.put(:config, config)
    |> Map.put(:headers, headers)
    |> Map.put(:url, url)
  end

  @spec send(t, Config.t()) :: Shopify.GraphQL.http_response_t()
  def send(request, config) do
    attempt = Map.get(request.private, :attempt, 0)

    attempt = attempt + 1

    private = Map.put(request.private, :attempt, attempt)

    request = Map.put(request, :private, private)

    request
    |> config.http_client.send(config.http_client_opts)
    |> retry(request, config)
    |> finish(config)
  end

  defp retry(response, _request, %_{ retry: retry }) when is_nil(retry) or retry == false do
    response
  end

  defp retry({ :ok, %{ status_code: status_code } } = response, request, config) when status_code >= 500 do
    do_retry(response, request, config)
  end

  defp retry({ :error, _ } = response, request, config) do
    do_retry(response, request, config)
  end

  defp retry(response, _request, _config) do
    response
  end

  defp do_retry(response, request, config) do
    attempt = Map.get(request.private, :attempt)

    max_attempts = Keyword.get(config.retry_opts, :max_attempts, 3)

    if max_attempts > attempt do
      seconds_to_wait = config.retry.wait_for(request, config)

      :timer.sleep(seconds_to_wait)

      request
      |> config.http_client.send(config.http_client_opts)
      |> retry(request, config)
    else
      response
    end
  end

  defp finish(response, config) do
    case response do
      { :ok, %{ status_code: status_code } = response } when status_code >= 400 ->
        { :error, Response.new(response, config) }
      { :ok, %{ status_code: status_code } = response } when status_code >= 200 ->
        { :ok, Response.new(response, config) }
      otherwise ->
        otherwise
    end
  end
end
