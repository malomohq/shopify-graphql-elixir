defmodule Shopify.GraphQL.Limiter.ProducerTest do
  use ExUnit.Case, async: true

  alias Shopify.GraphQL.{ Config, Limiter, Operation }

  describe "idle?/1" do
    test "returns true when idling", tags do
      { :ok, pid } = Limiter.Producer.start_link(process_opts(tags))

      assert Limiter.Producer.idle?(pid)
    end

    test "returns false while events are queued to be processed", tags do
      config = %Config{}
      operation = %Operation{}

      { :ok, pid } = Limiter.Producer.start_link(process_opts(tags))

      Limiter.Producer.retry(pid, operation, config)

      refute Limiter.Producer.idle?(pid)
    end
  end

  describe "process/4" do
    test "queues an event for processing", tags do
      config = %Config{}
      operation = %Operation{}
      self = self()

      { :ok, pid } = Limiter.Producer.start_link(process_opts(tags))

      Task.start(
        fn ->
          send(self, :done)

          Limiter.Producer.process(pid, operation, config)
        end
      )

      assert_receive :done

      assert Limiter.Producer.count(pid) == 1
    end

    test "fulfills demand", tags do
      config = %Config{}
      operation = %Operation{}
      self = self()

      parent = Map.get(tags, :module)
      partition_id = Map.get(tags, :line)

      producer = Limiter.Producer.name(parent, partition_id)

      Limiter.Partition.start_link([parent: parent, partition_id: partition_id])

      Task.start(
        fn ->
          send(self, :done)

          Limiter.Producer.process(producer, operation, config)
        end
      )

      assert_receive :done

      assert Limiter.Producer.count(producer) == 0
    end
  end

  test "start_link/1", tags do
    assert { :ok, _pid } = Limiter.Producer.start_link(process_opts(tags))
  end

  describe "throttle/1" do
    test "marks the producer as throttled", tags do
      { :ok, pid } = Limiter.Producer.start_link(process_opts(tags))

      Limiter.Producer.throttle(pid)

      assert Limiter.Producer.throttled?(pid)
    end

    test "stops fulfilling demand", tags do
      config = %Config{}
      operation = %Operation{}

      parent = Map.get(tags, :module)
      partition_id = Map.get(tags, :line)

      producer = Limiter.Producer.name(parent, partition_id)

      Limiter.Partition.start_link([parent: parent, partition_id: partition_id])

      Limiter.Producer.throttle(producer)

      Limiter.Producer.retry(producer, operation, config)

      assert Limiter.Producer.count(producer) == 1
    end
  end

  describe "unthrottle/1" do
    test "marks the producer as unthrottled", tags do
      { :ok, pid } = Limiter.Producer.start_link(process_opts(tags))

      Limiter.Producer.throttle(pid)

      assert Limiter.Producer.throttled?(pid)

      Limiter.Producer.unthrottle(pid)

      refute Limiter.Producer.throttled?(pid)
    end

    test "starts fulfilling demand", tags do
      config = %Config{}
      operation = %Operation{}

      parent = Map.get(tags, :module)
      partition_id = Map.get(tags, :line)

      producer = Limiter.Producer.name(parent, partition_id)

      Limiter.Partition.start_link([parent: parent, partition_id: partition_id])

      Limiter.Producer.throttle(producer)

      Limiter.Producer.retry(producer, operation, config)

      assert Limiter.Producer.count(producer) == 1

      Limiter.Producer.unthrottle(producer)

      assert Limiter.Producer.count(producer) == 0
    end
  end

  #
  # private
  #

  defp process_opts(tags) do
    parent = Map.get(tags, :module)
    partition_id = Map.get(tags, :line)

    name = Limiter.Producer.name(parent, partition_id)

    [name: name, parent: parent, partition_id: partition_id]
  end
end
