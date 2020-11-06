defmodule Shopify.GraphQL.Limiter.PartitionTest do
  use ExUnit.Case, async: true

  alias Shopify.GraphQL.{ Config, Limiter, Operation }

  test "starts a partition monitor when :monitor is true", tags do
    opts = process_opts(tags)
    opts = Keyword.put(opts, :monitor, true)

    parent = Keyword.get(opts, :parent)
    partition_id = Keyword.get(opts, :partition_id)

    partition_monitor = Limiter.PartitionMonitor.name(parent, partition_id)

    { :ok, _pid } = Limiter.Partition.start_link(opts)

    assert Process.whereis(partition_monitor) != nil
  end

  test "does not start a partition monitor when :monitor is false", tags do
    opts = process_opts(tags)
    opts = Keyword.put(opts, :monitor, false)

    parent = Keyword.get(opts, :parent)
    partition_id = Keyword.get(opts, :partition_id)

    partition_monitor = Limiter.PartitionMonitor.name(parent, partition_id)

    { :ok, _pid } = Limiter.Partition.start_link(opts)

    assert Process.whereis(partition_monitor) == nil
  end

  describe "idle?/1" do
    test "returns true when idling", tags do
      opts = process_opts(tags)

      parent = Keyword.get(opts, :parent)
      partition_id = Keyword.get(opts, :partition_id)

      consumer_supervisor = Limiter.ConsumerSupervisor.name(parent, partition_id)
      producer = Limiter.Producer.name(parent, partition_id)

      { :ok, _pid } = Limiter.Partition.start_link(opts)

      assert Limiter.Producer.idle?(producer)
      assert Limiter.ConsumerSupervisor.idle?(consumer_supervisor)
      assert Limiter.Partition.idle?(parent, partition_id)
    end

    test "returns false when Limiter.ConsumerSupervisor is supervising active processes", tags do
      config = %Config{}
      operation = %Operation{}

      opts = process_opts(tags)

      parent = Keyword.get(opts, :parent)
      partition_id = Keyword.get(opts, :partition_id)

      consumer_supervisor = Limiter.ConsumerSupervisor.name(parent, partition_id)
      producer = Limiter.Producer.name(parent, partition_id)

      { :ok, _pid } = Limiter.Partition.start_link(opts)

      Limiter.Producer.retry(producer, operation, config)

      assert Limiter.Producer.idle?(producer)
      refute Limiter.ConsumerSupervisor.idle?(consumer_supervisor)
      refute Limiter.Partition.idle?(parent, partition_id)
    end

    test "returns false while Limiter.Producer events are queued to be processed", tags do
      config = %Config{}
      operation = %Operation{}

      opts = process_opts(tags)

      parent = Keyword.get(opts, :parent)
      partition_id = Keyword.get(opts, :partition_id)

      consumer_supervisor = Limiter.ConsumerSupervisor.name(parent, partition_id)
      producer = Limiter.Producer.name(parent, partition_id)

      { :ok, _pid } = Limiter.Partition.start_link(opts)

      Limiter.Producer.throttle(producer)
      Limiter.Producer.retry(producer, operation, config)

      refute Limiter.Producer.idle?(producer)
      assert Limiter.ConsumerSupervisor.idle?(consumer_supervisor)
      refute Limiter.Partition.idle?(parent, partition_id)
    end
  end

  test "name/2", tags do
    parent = Map.get(tags, :module)
    partition_id = Map.get(tags, :line)

    name = :"#{parent}.Partition:#{partition_id}"

    assert name == Limiter.Partition.name(parent, partition_id)
  end

  test "start_link/1", tags do
    assert { :ok, _pid } = Limiter.Partition.start_link(process_opts(tags))
  end

  #
  # private
  #

  defp process_opts(tags) do
    parent = Map.get(tags, :module)
    partition_id = Map.get(tags, :line)

    [parent: parent, partition_id: partition_id]
  end
end
