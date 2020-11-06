defmodule Shopify.GraphQLTest do
  use ExUnit.Case, async: true

  alias Shopify.GraphQL.{ Config, Operation, Response }

  @query """
    {
      shop {
        name
      }
    }
  """

  describe "put_variable/3" do
    test "with query" do
      operation = Shopify.GraphQL.put_variable(@query, :var, "a")

      assert %Operation{ query: @query, variables: %{ var: "a" } } = operation
    end

    test "with operation" do
      operation = %Operation{ query: @query }

      operation = Shopify.GraphQL.put_variable(operation, :var, "a")

      assert %Operation{ query: @query, variables: %{ var: "a" } } = operation
    end
  end

  describe "send/2" do
    setup do
      bypass = Bypass.open()

      config = Config.new(%{ host: "localhost", port: bypass.port, protocol: "http" })

      %{ bypass: bypass, config: config }
    end

    test "with query", %{ bypass: bypass, config: config } do
      Bypass.expect(bypass, fn(conn) -> Plug.Conn.send_resp(conn, 200, "{\"ok\":true}") end)

      assert { :ok, %Response{} } = Shopify.GraphQL.send(@query, config)
    end

    test "with operation", %{ bypass: bypass, config: config } do
      Bypass.expect(bypass, fn(conn) -> Plug.Conn.send_resp(conn, 200, "{\"ok\":true}") end)

      operation = %Operation{ query: @query }

      assert { :ok, %Response{} } = Shopify.GraphQL.send(operation, config)
    end

    test "with limiter", %{ bypass: bypass, config: config } do
      config = Map.put(config, :limiter, true)

      Shopify.GraphQL.Limiter.start_link([])

      Bypass.expect(bypass, fn(conn) -> Plug.Conn.send_resp(conn, 200, "{\"ok\":true}") end)

      operation = %Operation{ query: @query }

      assert { :ok, %Response{} } = Shopify.GraphQL.send(operation, config)
    end
  end
end
