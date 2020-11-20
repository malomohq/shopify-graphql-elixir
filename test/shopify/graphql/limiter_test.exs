defmodule Shopify.GraphQL.LimiterTest do
  use ExUnit.Case, async: true

  describe "start_link/1" do
    test "without name" do
      { :ok, pid } = Shopify.GraphQL.Limiter.start_link([])

      assert pid == Process.whereis(Shopify.GraphQL.Limiter)
    end

    test "with name" do
      { :ok, pid } = Shopify.GraphQL.Limiter.start_link(name: MyLimiter)

      assert pid == Process.whereis(MyLimiter)
    end

    test "as global" do
      { :ok, pid } = Shopify.GraphQL.Limiter.start_link(name: { :global, MyLimiter })

      assert pid == :global.whereis_name(MyLimiter)
    end

    test "with registry" do
      { :ok, _ } = Registry.start_link(keys: :unique, name: MyRegistry)

      { :ok, pid } = Shopify.GraphQL.Limiter.start_link(name: { :via, Registry, { MyRegistry, MyLimiter } })

      assert [{ ^pid, _ }] = Registry.lookup(MyRegistry, MyLimiter)
    end
  end
end
