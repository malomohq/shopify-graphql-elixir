defmodule Shopify.GraphQL.Limiter.Partition do
  use Supervisor, restart: :temporary

  alias Shopify.GraphQL.{ Limiter }

  #
  # client
  #

  @doc """
  Determines whether the partition is in an idle state.

  A partition is considered idle when the producer's queue is empty and the
  consumer supervisor has no children.
  """
  @spec idle?(atom, Limiter.partition_id_t()) :: boolean
  def idle?(parent, partition_id) do
    consumer_supervisor = Limiter.ConsumerSupervisor.name(parent, partition_id)
    producer = Limiter.Producer.name(parent, partition_id)

    consumer_supervisor_is_idle? = Limiter.ConsumerSupervisor.idle?(consumer_supervisor)
    producer_is_idle? = Limiter.Producer.idle?(producer)

    consumer_supervisor_is_idle? && producer_is_idle?
  end

  @doc """
  Returns the name of a `Shopify.GraphQL.Limiter.Partition` process.

  A partition process's name is a combination of the parent limiter's name
  and a partition id. e.g. `Shopify.GraphQL.Limiter.Partition:<partition_id>`.
  """
  @spec name(atom, Limiter.partition_id_t()) :: atom
  def name(parent, partition_id) do
    Module.concat([parent, "Partition:#{partition_id}"])
  end

  @doc """
  Starts a `Shopify.GraphQL.Limiter.Partition` supervision tree and links it to
  the current process.
  """
  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(opts) do
    parent = Keyword.fetch!(opts, :parent)
    partition_id = Keyword.fetch!(opts, :partition_id)

    Supervisor.start_link(__MODULE__, opts, name: name(parent, partition_id))
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

  defp children(opts) do
    [
      { Limiter.Producer, opts_for_producer(opts) },
      { Limiter.ConsumerSupervisor, opts_for_consumer_supervisor(opts) }
    ]
  end

  defp opts_for_consumer_supervisor(opts) do
    consumer = Keyword.get(opts, :consumer, Limiter.Consumer)
    max_requests = Keyword.get(opts, :max_requests)
    parent = Keyword.fetch!(opts, :parent)
    partition_id = Keyword.fetch!(opts, :partition_id)

    Keyword.new()
    |> Keyword.put(:consumer, consumer)
    |> Keyword.put(:max_requests, max_requests)
    |> Keyword.put(:name, Limiter.ConsumerSupervisor.name(parent, partition_id))
    |> Keyword.put(:parent, parent)
    |> Keyword.put(:partition_id, partition_id)
    |> Keyword.put(:producer, Limiter.Producer.name(parent, partition_id))
    |> Enum.reject(fn({ _k, v }) -> is_nil(v) end)
  end

  defp opts_for_producer(opts) do
    parent = Keyword.fetch!(opts, :parent)
    partition_id = Keyword.fetch!(opts, :partition_id)
    restore_to = Keyword.get(opts, :restore_to)

    Keyword.new()
    |> Keyword.put(:name, Limiter.Producer.name(parent, partition_id))
    |> Keyword.put(:parent, parent)
    |> Keyword.put(:partition_id, partition_id)
    |> Keyword.put(:restore_to, restore_to)
    |> Enum.reject(fn({ _k, v }) -> is_nil(v) end)
  end
end
