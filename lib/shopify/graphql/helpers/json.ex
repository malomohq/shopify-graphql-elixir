defmodule Shopify.GraphQL.Helpers.JSON do
  @spec decode(String.t(), Shopify.GraphQL.Config.t()) :: map
  def decode(string, config) do
    case config.json_codec.decode(string) do
      { :ok, result } ->
        result
      { :error, _reason } ->
        %{}
    end
  end


  @spec encode(map, Shopify.GraphQL.Config.t()) :: String.t()
  def encode(map, config) do
    case config.json_codec.encode(map) do
      { :ok, result } ->
        result
      { :error, _reason } ->
        ""
    end
  end
end
