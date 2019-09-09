defmodule Shopify.GraphQL.Response do
  alias Shopify.GraphQL.{ Client, Config, Helpers }

  @type t ::
          %__MODULE__{
            body: map,
            headers: [{ String.t(), String.t() }],
            private: map,
            status_code: pos_integer
          }

  defstruct body: nil,
            headers: nil,
            private: %{},
            status_code: nil

  @spec new(Client.response_t(), Config.t(), map) :: t
  def new(response, config, private) do
    %__MODULE__{
      body: Helpers.JSON.decode(response.body, config),
      headers: response.headers,
      private: private,
      status_code: response.status_code
    }
  end
end
