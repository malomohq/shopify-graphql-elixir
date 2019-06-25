defmodule Shopify.GraphQL.Operation do
  @type t ::
          %__MODULE__{ query: String.t(), variables: map }

  defstruct query: nil, variables: %{}
end
