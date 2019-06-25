defmodule Shopify.GraphQL.Response do
  @type t ::
          %__MODULE__{
            body: map,
            headers: [{ String.t(), String.t() }],
            status_code: pos_integer
          }

  defstruct [:body, :headers, :status_code]
end
