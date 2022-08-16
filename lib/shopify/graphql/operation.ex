defmodule Shopify.GraphQL.Operation do
  @type t ::
          %__MODULE__{ query: String.t(), variables: map }

  defstruct [query: nil, variables: %{}]

  @spec put_variable(binary | t, atom | binary, any) :: t
  def put_variable(query, name, value) when is_binary(query) do
    put_variable(%__MODULE__{ query: query }, name, value)
  end

  def put_variable(operation, name, value) do
    variables =
      operation
      |> Map.get(:variables)
      |> Map.put(name, value)

    %{ operation | variables: variables }
  end

  @spec put_variables(binary | t, map) :: t
  def put_variables(query, variables) when is_binary(query) do
    put_variables(%__MODULE__{query: query}, variables)
  end

  def put_variables(operation, variables) do
    variables = Map.merge(operation.variables, variables)

    %{operation | variables: variables}
  end
end
