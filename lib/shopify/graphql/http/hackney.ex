defmodule Shopify.GraphQL.Http.Hackney do
  @behaviour Shopify.GraphQL.Http

  @impl true
  def send(request, opts) do
    opts = opts ++ [:with_body]

    IO.inspect request.headers

    response =
      :hackney.request(
        request.method,
        request.url,
        request.headers,
        request.body,
        opts
      )

    case response do
      { :ok, status_code, headers } ->
        { :ok, %{ body: "", headers: headers, status_code: status_code } }
      { :ok, status_code, headers, body } ->
        { :ok, %{ body: body, headers: headers, status_code: status_code } }
      otherwise ->
        otherwise
    end
  end
end
