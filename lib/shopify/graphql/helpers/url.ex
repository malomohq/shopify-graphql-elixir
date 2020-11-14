defmodule Shopify.GraphQL.Helpers.Url do
  @moduledoc false

  alias Shopify.GraphQL.{ Config }

  @spec to_string(Config.t()) :: String.t()
  def to_string(config) do
    config
    |> to_uri()
    |> URI.to_string()
  end

  @spec to_uri(Config.t()) :: URI.t()
  def to_uri(config) do
    %URI{}
    |> Map.put(:port, config.http_port)
    |> Map.put(:scheme, config.http_protocol)
    |> Map.put(:path, "#{config.http_path}/#{config.version}#{config.endpoint}")
    |> put_host(config)
  end

  defp put_host(uri, %_{ shop: shop } = config) when not is_nil(shop) do
    Map.put(uri, :host, "#{shop}.#{config.http_host}")
  end

  defp put_host(uri, config) do
    Map.put(uri, :host, config.http_host)
  end
end
