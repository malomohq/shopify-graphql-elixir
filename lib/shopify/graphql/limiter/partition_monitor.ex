defmodule Shopify.GraphQL.Limiter.PartitionMonitor do
  use GenServer

  alias Shopify.GraphQL.{ Limiter }

  #
  # client
  #

  @doc """
  Returns the name of a `Shopify.GraphQL.Limiter.PartitionMonitor` process.

  A partition monitor process's name is a combination of the parent limiter's
  name and a partition id. e.g.
  `Shopify.GraphQL.Limiter.PartitionMonitor:<partition_id>`.
  """
  @spec name(atom, Limiter.partition_id_t()) :: atom
  def name(parent, partition_id) do
    Module.concat([parent, "PartitionMonitor:#{partition_id}"])
  end

  @doc """
  Starts a `Shopify.GraphQL.Limiter.Partition` process and links it to the
  supervision tree.
  """
  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(opts) do
    monitor = Keyword.get(opts, :monitor, true)

    if monitor do
      parent = Keyword.fetch!(opts, :parent)
      partition_id = Keyword.fetch!(opts, :partition_id)

      GenServer.start_link(__MODULE__, opts, name: name(parent, partition_id))
    else
      :ignore
    end
  end

  #
  # callbacks
  #

  @impl true
  def init(opts) do
    state =
      Map.new()
      |> Map.put(:idling?, false)
      |> Map.put(:parent, Keyword.fetch!(opts, :parent))
      |> Map.put(:partition_id, Keyword.fetch!(opts, :partition_id))
      |> Map.put(:timeout, Keyword.get(opts, :timeout, 3_500))

    { :ok, state, { :continue, :init } }
  end

  @impl true
  def handle_continue(:init, state) do
    schedule(state)

    { :noreply, state }
  end

  @impl true
  def handle_info(:monitor, %{ idling?: false } = state) do
    state = idling?(state)

    schedule(state)

    { :noreply, state }
  end

  @impl true
  def handle_info(:monitor, %{ idling?: true } = state) do
    state = idling?(state)

    case Map.get(state, :idling?) do
      true ->
        stop(state)
      _otherwise ->
        schedule(state)
    end

    { :noreply, state }
  end

  #
  # private
  #

  defp idling?(state) do
    parent = Map.get(state, :parent)
    partition_id = Map.get(state, :partition_id)

    idling? = Limiter.Partition.idle?(parent, partition_id)

    Map.put(state, :idling?, idling?)
  end

  defp schedule(state) do
    timeout = Map.get(state, :timeout)

    Process.send_after(self(), :monitor, timeout)
  end

  defp stop(state) do
    parent = Map.get(state, :parent)
    partition_id = Map.get(state, :partition_id)

    Limiter.Partition.stop(parent, partition_id)
  end
end
