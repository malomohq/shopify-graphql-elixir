defmodule Shopify.GraphQL.Limiter.ConsumerSupervisorTest do
  use ExUnit.Case, async: true

  alias Shopify.GraphQL.{ Limiter }

  defmodule ObservableConsumer do
    use Task

    def start_link(event) do
      Task.start_link(__MODULE__, :run, [event])
    end

    def run(_event) do
      Process.sleep(1_000)
    end
  end

  defmodule ObservableProducer do
    use GenStage

    def start_link(opts) do
      GenStage.start_link(__MODULE__, opts)
    end

    def push(server, owner) do
      GenStage.call(server, { :push, %{ owner: owner } })
    end

    @impl true
    def init(opts) do
      { :producer, Enum.into(opts, %{}) }
    end

    @impl true
    def handle_call({ :push, event }, _from, state) do
      { :reply, :ok, [event], state }
    end

    @impl true
    def handle_demand(demand, state) do
      state = Map.put(state, :demand, demand)

      { :noreply, [], state }
    end
  end

  describe "idle?/1" do
    test "returns true when idling", tags do
      { :ok, pid } = Limiter.ConsumerSupervisor.start_link(process_opts(tags))

      assert true == Limiter.ConsumerSupervisor.idle?(pid)
    end

    test "returns false when supervising active processes", tags do
      opts = process_opts(tags)

      producer = Keyword.get(opts, :producer)

      { :ok, pid } = Limiter.ConsumerSupervisor.start_link(opts)

      ObservableProducer.push(producer, self())

      assert false == Limiter.ConsumerSupervisor.idle?(pid)
    end
  end

  test "start_link/1", tags do
    assert { :ok, _pid } = Limiter.ConsumerSupervisor.start_link(process_opts(tags))
  end

  #
  # private
  #

  defp process_opts(tags) do
    parent = Map.get(tags, :module)
    partition_id = Map.get(tags, :line)

    { :ok, producer } = ObservableProducer.start_link([])

    name = Limiter.ConsumerSupervisor.name(parent, partition_id)

    [
      consumer: ObservableConsumer,
      name: name,
      parent: parent,
      partition_id: partition_id,
      producer: producer
    ]
  end
end
