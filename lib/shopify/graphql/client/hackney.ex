defmodule Shopify.GraphQL.Client.Hackney do
  @behaviour Shopify.GraphQL.Client

  @spec request(
          Shopify.GraphQL.Client.method_t(),
          String.t(),
          Shopify.GraphQL.Client.headers_t(),
          String.t(),
          any
        ) :: { :ok, Shopify.GraphQL.Client.response_t() } | { :error, any }
  def request(method, url, headers, body, opts) do
    opts = opts ++ [:with_body]

    response =
      :hackney.request(
        method,
        url,
        headers,
        body,
        opts
      )

      package(response)
  end

  defp package({ :ok, status_code, headers }) do
    response = %{ body: "", headers: headers, status_code: status_code }

    { :ok, response }
  end

  defp package({ :ok, status_code, headers, body }) do
    response = %{ body: body, headers: headers, status_code: status_code }

    { :ok, response }
  end

  defp package(otherwise) do
    otherwise
  end
end
