defmodule Shopify.GraphQL.Config do
  @type t ::
          %__MODULE__{
            access_token: String.t(),
            endpoint: String.t(),
            headers: list({ String.t(), any }),
            host: String.t(),
            http_client: module,
            http_client_opts: any,
            json_codec: module,
            limiter: atom | boolean,
            limiter_opts: Keyword.t(),
            path: String.t(),
            port: String.t(),
            protocol: String.t(),
            retry: boolean,
            retry_opts: Keyword.t(),
            shop: String.t(),
            version: String.t()
          }

  defstruct access_token: nil,
            endpoint: "graphql.json",
            headers: [],
            host: "myshopify.com",
            http_client: Shopify.GraphQL.Client.Hackney,
            http_client_opts: [],
            json_codec: Jason,
            limiter: false,
            limiter_opts: [],
            path: "admin/api",
            port: nil,
            protocol: "https",
            retry: false,
            retry_opts: [],
            shop: nil,
            version: nil

  @doc """
  Build a config struct.

  Config is composed of values provided through application configuration and a
  map of optional overrides. If overrides are provided they will be merged with
  the application configuration.
  """
  @spec new(map | t) :: t
  def new(overrides \\ %__MODULE__{})

  def new(%__MODULE__{} = overrides) do
    Application.get_all_env(:shopify_graphql)
    |> Enum.into(%{})
    |> Map.merge(overrides)
  end

  def new(overrides) do
    overrides = struct(__MODULE__, overrides)

    new(overrides)
  end
end
