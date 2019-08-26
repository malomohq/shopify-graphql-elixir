defmodule Shopify.GraphQLTest do
  use ExUnit.Case, async: true

  alias Shopify.GraphQL.{ Operation, Response }

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

      config = %{ host: "localhost", port: bypass.port, protocol: "http", shop: "a-shop" }

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

    test "returns { :ok, %Shopify.GraphQL.Response{} } when response has an HTTP status code of 200", %{ bypass: bypass, config: config } do
      Bypass.expect(bypass, fn(conn) -> Plug.Conn.send_resp(conn, 200, "{\"ok\":true}") end)

      assert { :ok, %Response{} } = Shopify.GraphQL.send(@query, config)
    end

    test "returns { :error, %Shopify.GraphQL.Response{} } when response has an HTTP status code of 400", %{ bypass: bypass, config: config } do
      Bypass.expect(bypass, fn(conn) -> Plug.Conn.send_resp(conn, 400, "{\"ok\":true}") end)

      assert { :error, %Response{} } = Shopify.GraphQL.send(@query, config)
    end

    test "makes a request", %{ bypass: bypass, config: config } do
      Bypass.expect(bypass, fn
        (conn) ->
          conn = Plug.Parsers.call(conn, Plug.Parsers.init([json_decoder: Jason, parsers: [:json], pass: ["*/*"]]))

          assert conn.body_params == %{ "query" => @query, "variables" => %{ "var" => "a" } }
          assert conn.method == "POST"

          Plug.Conn.send_resp(conn, 200, "{\"ok\":true}")
      end)

      @query
      |> Shopify.GraphQL.put_variable(:var, "a")
      |> Shopify.GraphQL.send(config)
    end
  end
end
