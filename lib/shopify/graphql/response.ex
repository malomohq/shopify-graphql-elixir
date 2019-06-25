defmodule Shopify.GraphQL.Response do
  alias Shopify.GraphQL.{ Helpers }

  @type t ::
          %__MODULE__{
            body: map,
            headers: [{ String.t(), String.t() }],
            status_code: pos_integer
          }

  defstruct [:body, :headers, :status_code]

  def new(response, config) do
    %__MODULE__{
      body: Helpers.JSON.decode(response.body, config),
      headers: response.headers,
      status_code: response.status_code
    }
  end
end
