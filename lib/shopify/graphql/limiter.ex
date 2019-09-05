defmodule Shopify.GraphQL.Limiter do
  use DynamicSupervisor

  @type partition_id_t :: atom | String.t()

  #
  # client
  #

  @doc """
  Starts a `Shopify.GraphQL.Limiter` supervision tree and links it to the
  current process.
  """
  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc """
  Starts a partition.
  """
  @spec start_partition(atom, partition_id_t) ::
        { :ok, pid } | { :error, term }
  def start_partition(server, partition_id) do
    spec = { __MODULE__.Partition, parent: server, partition_id: partition_id }

    case DynamicSupervisor.start_child(server, spec) do
      { :ok, pid } ->
        { :ok, pid }
      { :error, { :already_started, pid } } ->
        { :ok, pid }
      otherwise ->
        otherwise
    end
  end

  #
  # callbacks
  #

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
