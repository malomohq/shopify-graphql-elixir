if Code.ensure_loaded?(GenStage) do
  defmodule Shopify.GraphQL.Limiter.Partition do
    use Supervisor, restart: :temporary

    alias Shopify.GraphQL.{ Config, Helpers, Limiter }

    #
    # client
    #

    @spec idle?(Supervisor.name()) :: Supervisor.name()
    def idle?(partition) do
      Limiter.Producer.idle?(partition) &&
      Limiter.ConsumerSupervisor.idle?(partition)
    end

    @spec name(Supervisor.name(), Config.t()) :: Supervisor.name()
    def name(limiter, config) do
      id = config |> Helpers.Url.to_uri() |> Map.get(:host)

      Helpers.Limiter.process_name(limiter, :"Partition:#{id}")
    end

    @spec start_link(Keyword.t()) :: Supervisor.on_start()
    def start_link(opts) do
      partition_opts = Keyword.new()
      partition_opts = Keyword.put(partition_opts, :partition, opts[:name])
      partition_opts = Keyword.put(partition_opts, :limiter_opts, opts[:limiter_opts])

      Supervisor.start_link(__MODULE__, partition_opts, name: opts[:name])
    end

    #
    # callbacks
    #

    @impl true
    def init(opts) do
      Supervisor.init(children(opts), strategy: :one_for_one)
    end

    defp children(opts) do
      [
        { Limiter.PartitionMonitor, opts },
        { Limiter.Producer, opts },
        { Limiter.ConsumerSupervisor, opts }
      ]
    end
  end
end
