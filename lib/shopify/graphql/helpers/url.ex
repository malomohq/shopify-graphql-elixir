defmodule Shopify.GraphQL.Helpers.URL do
  @moduledoc false

  @spec new(Shopify.GraphQL.Config.t()) :: String.t()
  def new(config) do
    %URI{ port: config.port, scheme: config.protocol }
    |> put_host(config)
    |> put_path(config)
    |> URI.to_string()
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
