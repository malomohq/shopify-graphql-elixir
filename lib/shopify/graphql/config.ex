defmodule Shopify.GraphQL.Config do
  @type t ::
          %__MODULE__{
            access_token: String.t(),
            endpoint: String.t(),
            host: String.t(),
            http_client: module,
            http_client_opts: any,
            json_codec: module,
            path: String.t(),
            port: String.t(),
            protocol: String.t(),
            shop: String.t(),
            version: String.t()
          }

  defstruct access_token: nil,
            endpoint: "/graphql.json",
            host: "myshopify.com",
            http_client: Shopify.GraphQL.Client.Hackney,
            http_client_opts: [],
            json_codec: Jason,
            path: "/admin/api",
            port: nil,
            protocol: "https",
            shop: nil,
            version: "2019-04"

  @doc """
  Build a config struct.

  Config is composed of values provided through application configuration and a
  map of optional overrides. If overrides are provided they will be merged with
  the application configuration.
  """
  @spec new(map) :: t
  def new(overrides \\ %{}) do
    config =
      Application.get_all_env(:shopify_graphql)
      |> Enum.into(%{})
      |> Map.merge(overrides)

    struct(__MODULE__, config)
  end
end
