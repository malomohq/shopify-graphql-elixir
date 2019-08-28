defmodule Shopify.GraphQL.Helpers.URL do
  @moduledoc false

  @spec to_string(Shopify.GraphQL.Config.t()) :: String.t()
  def to_string(config) do
    config
    |> to_uri()
    |> URI.to_string()
  end

  @spec to_uri(Shopify.GraphQL.Config.t()) :: URI.t()
  def to_uri(config) do
    %URI{ port: config.port, scheme: config.protocol }
    |> put_host(config)
    |> put_path(config)
  end

  defp put_host(uri, %{ shop: shop } = config) when not is_nil(shop) do
    Map.put(uri, :host, "#{shop}.#{config.host}")
  end

  defp put_host(uri, config) do
    Map.put(uri, :host, config.host)
  end

  defp put_path(uri, config) do
    Map.put(uri, :path, "/#{config.path}/#{config.version}/#{config.endpoint}")
  end
end
