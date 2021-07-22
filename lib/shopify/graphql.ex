defmodule Shopify.GraphQL do
  alias Shopify.GraphQL.{ Config, Limiter, Operation, Request, Response }

  @type http_headers_t ::
          [{ String.t(), String.t() }]

  @type http_method_t ::
          :delete | :get | :head | :patch | :post | :put

  @type http_response_t ::
          { :ok, Response.t() } | { :error, Response.t() | any }

  @type http_status_code_t ::
          pos_integer

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

  You must also pass configuration as a keyword list to the second argument.
  This allows you to use different config values on a per-request basis.
  """
  @spec send(String.t() | Operation.t(), Keyword.t()) :: http_response_t
  def send(query, config) when is_binary(query) do
    __MODULE__.send(%Operation{ query: query }, config)
  end

  def send(operation, config) do
    config = Config.new(config)

    request = Request.new(operation, config)

    cond do
      config.limiter == false ->
        Request.send(request, config)
      config.limiter == true ->
        Limiter.send(Shopify.GraphQL.Limiter, request, config)
      true ->
        Limiter.send(config.limiter, request, config)
    end

  end
end
