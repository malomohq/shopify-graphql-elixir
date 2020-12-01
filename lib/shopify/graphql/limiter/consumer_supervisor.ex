if Code.ensure_loaded?(GenStage) do
  defmodule Shopify.GraphQL.Limiter.ConsumerSupervisor do
    use ConsumerSupervisor

    alias Shopify.GraphQL.{ Helpers, Limiter }

    #
    # client
    #

    @spec idle?(Supervisor.name()) :: boolean
    def idle?(partition) do
      partition
      |> name()
      |> ConsumerSupervisor.count_children()
      |> Map.get(:active) == 0
    end

    @spec name(Supervisor.name()) :: Supervisor.name()
    def name(partition) do
      Helpers.Limiter.process_name(partition, ConsumerSupervisor)
    end

    @spec start_link(Keyword.t()) :: GenServer.on_start()
    def start_link(opts) do
      ConsumerSupervisor.start_link(__MODULE__, opts, name: name(opts[:partition]))
    end

    #
    # callbacks
    #

    @impl true
    def init(opts) do
      limiter_opts = Keyword.get(opts, :limiter_opts)

      partition = Keyword.get(opts, :partition)

      max_demand = Keyword.get(limiter_opts, :max_requests, 3)

      producer = Limiter.Producer.name(partition)

      ConsumerSupervisor.init(children(), strategy: :one_for_one, subscribe_to: [{ producer, max_demand: max_demand }])
    end

    defp children do
      spec = Map.new()
      spec = Map.put(spec, :id, Limiter.Consumer)
      spec = Map.put(spec, :restart, :transient)
      spec = Map.put(spec, :start, { Limiter.Consumer, :start_link, [] })

      [spec]
    end
  end
end
