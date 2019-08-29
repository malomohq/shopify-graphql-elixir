defmodule Shopify.GraphQL.Limiter.Shop do
  use Supervisor, restart: :temporary

  #
  # client
  #

  @doc """
  Starts a `Shopify.GraphQL.Limiter.Shop` supervision tree and links it to the
  current process.
  """
  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  #
  # callbacks
  #

  @impl true
  def init(opts) do
    Supervisor.init(children(opts), strategy: :one_for_one)
  end

  #
  # private
  #

  defp children(_opts) do
    []
  end
end
