defmodule Shopify.GraphQL do
  alias Shopify.GraphQL.{ Config, Limiter, Operation, Request, Response }

  @type http_headers_t :: [{ String.t(), String.t() }]

  @type http_method_t :: :delete | :get | :post | :put

  @type response_t :: { :ok, Response.t() } | { :error, Response.t() | any }

  @doc """
  Add a variable to the operation.

  It's possible to pass either a `Shopify.GraphQL.Operation` struct or, as a
  convenience, a binary query.
  """
  @spec put_variable(binary | Operation.t(), binary | atom, any) :: Operation.t()
  defdelegate put_variable(operation_or_query, name, value),
    to: Operation

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
  @spec send(binary | Operation.t(), map) :: response_t
  def send(query, config) when is_binary(query) do
    __MODULE__.send(%Operation{ query: query }, config)
  end

  def send(operation, config) do
    config = Config.new(config)

    cond do
      config.limiter == false ->
        Request.send(operation, config)
      config.limiter == true ->
        Limiter.send(Limiter, operation, config)
      true ->
        Limiter.send(config.limiter, operation, config)
    end
  end
end
