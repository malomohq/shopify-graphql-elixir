defmodule Shopify.GraphQL.Limiter do
  use DynamicSupervisor

  alias Shopify.GraphQL.{ Config, Helpers, Limiter, Operation }

  @type name_t :: atom | { :via, module, { module, String.t() } }

  @type partition_id_t :: atom | String.t()

  #
  # client
  #

  @spec get_partition_id(Config.t()) :: String.t()
  def get_partition_id(config) do
    config
    |> Helpers.URL.to_uri()
    |> Map.get(:host)
  end

  @spec send(atom, Operation.t(), Config.t()) :: Shopify.GraphQL.response_t()
  def send(server, operation, config) do
    partition_id = get_partition_id(config)

    start_partition(server, partition_id, config.limiter_opts)

    producer = Limiter.Producer.name(server, partition_id)

    Limiter.Producer.process(producer, operation, config)
  end

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
  @spec start_partition(atom, partition_id_t, Keyword.t()) ::
        { :ok, pid } | { :error, term }
  def start_partition(server, partition_id, opts) do
    opts = [parent: server, partition_id: partition_id] ++ opts
    spec = { __MODULE__.Partition, opts }

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
