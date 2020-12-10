if Code.ensure_loaded?(GenStage) do
  defmodule Shopify.GraphQL.Limiter.PartitionMonitor do
    use GenServer

    alias Shopify.GraphQL.{ Helpers, Limiter }

    #
    # client
    #

    @spec name(Supervisor.name()) :: Supervisor.name()
    def name(partition) do
      Helpers.Limiter.process_name(partition, PartitionMonitor)
    end

    @spec pid(Supervisor.name()) :: pid
    def pid(partition) do
      partition
      |> name()
      |> Helpers.Limiter.pid()
    end

    @spec restart(Supervisor.name()) :: :ok
    def restart(partition) do
      GenServer.call(name(partition), :restart)
    end

    @spec start(Supervisor.name()) :: reference
    def start(partition) do
      Process.send_after(pid(partition), :check, 15_000)
    end

    @spec start_link(Keyword.t()) :: GenServer.on_start()
    def start_link(opts) do
      monitor = Keyword.get(opts[:limiter_opts], :monitor, true)

      if monitor do
        GenServer.start_link(__MODULE__, opts, name: name(opts[:partition]))
      else
        :ignore
      end
    end

    #
    # callbacks
    #

    @impl true
    def init(opts) do
      partition = Keyword.get(opts, :partition)

      state = Map.new()
      state = Map.put(state, :partition, partition)
      state = Map.put(state, :timer, start(partition))

      { :ok, state }
    end

    @impl true
    def handle_call(:restart, _from, state) do
      Process.cancel_timer(state[:timer])

      { :reply, :ok, %{ state | timer: start(state[:partition]) } }
    end

    @impl true
    def handle_info(:check, state) do
      partition = Map.get(state, :partition)

      if Limiter.Partition.idle?(partition) do
        Supervisor.stop(partition)
      else
        { :noreply, %{ state | timer: start(partition) } }
      end
    end
  end
end
