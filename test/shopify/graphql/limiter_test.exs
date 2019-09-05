defmodule Shopify.GraphQL.LimiterTest do
  use ExUnit.Case, async: true

  alias Shopify.GraphQL.{ Limiter }

  test "start_link/1", tags do
    line = Map.get(tags, :line)
    module = Map.get(tags, :module)

    name = Module.concat(["#{module}:#{line}"])

    assert { :ok, _pid } = Limiter.start_link(name: name)
  end

  describe "start_partition/2" do
    test "returns { :ok, pid } if not partition has been started", tags do
      line = Map.get(tags, :line)
      module = Map.get(tags, :module)

      parent = Module.concat(["#{module}:#{line}"])
      partition_id = line

      Limiter.start_link(name: parent)

      assert { :ok, _pid } = Limiter.start_partition(parent, partition_id)
    end

    test "returns { :ok, pid } if the partition has already been started", tags do
      line = Map.get(tags, :line)
      module = Map.get(tags, :module)

      parent = Module.concat(["#{module}:#{line}"])
      partition_id = line

      Limiter.start_link(name: parent)

      assert { :ok, _pid } = Limiter.start_partition(parent, partition_id)
      assert { :ok, _pid } = Limiter.start_partition(parent, partition_id)
    end
  end
end
