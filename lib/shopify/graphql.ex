defmodule Shopify.GraphQL do
  @type http_headers_t :: [{ String.t(), String.t() }]

  @type http_method_t :: :delete | :get | :post | :put

  @doc """
  Add a variable to the operation.

  It's possible to pass either a `Shopify.GraphQL.Operation` struct or, as a
  convenience, a binary query.
  """
  @spec put_variable(
          binary | Shopify.GraphQL.Operation.t(),
          binary | atom,
          any
        ) :: Shopify.GraphQL.Operation.t()
  defdelegate put_variable(operation_or_query, name, value),
    to: Shopify.GraphQL.Operation

  @doc """
  Send a GraphQL operation to Shopify.

  It's possible to send either a `Shopify.GraphQL.Operation` struct or, as a
  convenience, a binary query.

      query =
        \"\"\"
        {
          shop {
            name
          }
        }
        \"\"\"

      operation = %Shopify.GraphQL.Operation{ query: query }

      Shopify.GraphQL.send(operation)

  or

      query =
        \"\"\"
        {
          shop {
            name
          }
        }
        \"\"\"

      Shopify.GraphQL.send(query)

  You may also pass an optional map of config overrides. This allows you to
  use different config values on a per-request basis.
  """
  @spec send(binary | Shopify.GraphQL.Operation.t(), map) ::
        { :ok, Shopify.GraphQL.Response.t() } | { :error, any }
  defdelegate send(operation_or_query, config \\ %{}),
    to: Shopify.GraphQL.Request
end
