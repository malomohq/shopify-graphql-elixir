defmodule Shopify.GraphQL.Limiter.ConsumerSupervisor do
  use ConsumerSupervisor

  alias Shopify.GraphQL.{ Limiter }

  #
  # client
  #

  @doc """
  Determines whether the consumer supervisor is in an idle state.

  A consumer supervisor is considered idle when it is not supervising any
  active processes.
  """
  @spec idle?(Supervisor.supervisor()) :: boolean
  def idle?(server) do
    result = ConsumerSupervisor.count_children(server)

    Map.get(result, :active) == 0
  end

  @doc """
  Returns the name of a `Shopify.GraphQL.Limiter.ConsumerSupervisor` process.

  A consumer supervisor process's name is a combination of the parent limiter's
  name and a partition id. e.g.
  `Shopify.GraphQL.Limiter.ConsumerSupervisor:<partition_id>`.
  """
  @spec name(atom, Shopify.GraphQL.Limiter.partition_id_t()) :: atom
  def name(parent, partition_id) do
    Module.concat([parent, "ConsumerSupervisor:#{partition_id}"])
  end

  @doc """
  Starts a `Shopify.GraphQL.Limiter.ConsumerSupervisor` supervision tree and
  links it to the current process.
  """
  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(opts) do
    ConsumerSupervisor.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  #
  # callbacks
  #

  @impl true
  def init(opts) do
    max_demand = Keyword.get(opts, :max_requests, 3)
    producer = Keyword.get(opts, :producer)

    ConsumerSupervisor.init(children(opts), [strategy: :one_for_one, subscribe_to: [{ producer, max_demand: max_demand }]])
  end

  #
  # private
  #

  defp children(opts) do
    consumer = Keyword.get(opts, :consumer, Limiter.Consumer)

    [
      %{ id: consumer, start: { consumer, :start_link, [] }, restart: :transient }
    ]
  end
end
