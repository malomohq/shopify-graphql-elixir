defmodule Shopify.GraphQL.Limiter do
  use DynamicSupervisor

  alias Shopify.GraphQL.{ Config, Limiter, Request }

  @type name_t ::
          atom | { :global, any } | { :via, module, any }

  #
  # client
  #

  @spec send(Limiter.name_t(), Request.t(), Config.t()) :: Shopify.GraphQL.http_response_t()
  def send(limiter, request, config) do
    ensure_gen_stage_loaded!()

    partition = Limiter.Partition.name(limiter, config)

    { :ok, _ } = start_partition(limiter, config)

    Limiter.Producer.send(partition, request, config)
  end

  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(opts) do
    ensure_gen_stage_loaded!()

    name = Keyword.get(opts, :name, __MODULE__)

    DynamicSupervisor.start_link(__MODULE__, :ok, name: name)
  end

  @spec start_partition(Limiter.name_t(), Config.t()) :: { :ok, pid } | { :error, term }
  def start_partition(limiter, config) do
    partition = Limiter.Partition.name(limiter, config)

    opts = Keyword.new()
    opts = Keyword.put(opts, :limiter_opts, config.limiter_opts)
    opts = Keyword.put(opts, :name, partition)

    spec = { Limiter.Partition, opts }

    case DynamicSupervisor.start_child(limiter, spec) do
      { :error, { :already_started, pid } } ->
        Limiter.PartitionMonitor.restart(partition, config.limiter_opts)

        { :ok, pid }
      otherwise ->
        otherwise
    end
  end

  defp ensure_gen_stage_loaded! do
    unless Code.ensure_loaded?(GenStage) do
      raise """
      You are trying to use Shopify.GraphQL.Limiter but GenStage is not loaded.
      Make sure you have defined gen_stage as a dependency.
      """
    end
  end

  #
  # callbacks
  #

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
