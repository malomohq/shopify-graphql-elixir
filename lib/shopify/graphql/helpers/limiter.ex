defmodule Shopify.GraphQL.Helpers.Limiter do
  @moduledoc false

  alias Shopify.GraphQL.{ Limiter }

  @spec pid(Limiter.name_t()) :: pid
  def pid({ :via, registry_mod, { registry, key } }) do
    [{ pid, _ }] = registry_mod.lookup(registry, key)

    pid
  end

  def pid({ :global, name }) do
    :global.whereis_name(name)
  end

  def pid(name) do
    Process.whereis(name)
  end

  @spec process_name(Limiter.name_t(), atom) :: Limiter.name_t()
  def process_name({ :via, registry_mod, { registry, key } }, name) do
    { :via, registry_mod, { registry, process_name(key, name) } }
  end

  def process_name({ :global, key }, name) do
    { :global, process_name(key, name) }
  end

  def process_name(key, name) do
    Module.concat([key, name])
  end
end
