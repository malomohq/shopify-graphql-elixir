defmodule Shopify.GraphQLTest do
  use ExUnit.Case, async: true

  alias Shopify.GraphQL.{ Http, Response }

  @ok_resp %{ body: "{\"ok\":true}", headers: [], status_code: 200 }

  @not_ok_resp %{ body: "{\"ok\":false}", headers: [], status_code: 400 }

  test "sends a POST request" do
    Http.Mock.start_link()

    response = { :ok, @ok_resp }

    Http.Mock.put_response(response)

    Shopify.GraphQL.send("{ shop { name } }", http_client: Http.Mock)

    assert :post == Http.Mock.get_request_method()
  end

  test "sends the proper HTTP headers" do
    Http.Mock.start_link()

    response = { :ok, @ok_resp }

    Http.Mock.put_response(response)

    Shopify.GraphQL.send("{ shop { name } }", access_token: "thisisfake", http_client: Http.Mock, http_headers: [{ "x-custom-header", "true" }])

    assert { "content-type", "application/json" } in Http.Mock.get_request_headers()
    assert { "x-shopify-access-token", "thisisfake" } in Http.Mock.get_request_headers()
    assert { "x-custom-header", "true" } in Http.Mock.get_request_headers()
  end

  test "returns :ok when the request is successful" do
    Http.Mock.start_link()

    response = { :ok, @ok_resp }

    Http.Mock.put_response(response)

    result = Shopify.GraphQL.send("{ shop { name } }", http_client: Http.Mock)

    assert { :ok, %Response{} } = result
  end

  test "returns :error when the request is not successful" do
    Http.Mock.start_link()

    response = { :ok, @not_ok_resp }

    Http.Mock.put_response(response)

    result = Shopify.GraphQL.send("{ shop { name } }", http_client: Http.Mock)

    assert { :error, %Response{} } = result
  end

  test "passes the response through when unrecognized" do
    Http.Mock.start_link()

    response = { :error, :timeout }

    Http.Mock.put_response(response)

    result = Shopify.GraphQL.send("{ shop { name } }", http_client: Http.Mock)

    assert ^response = result
  end

  test "properly handles retries" do
    Http.Mock.start_link()

    Http.Mock.put_response({ :error, :timeout })
    Http.Mock.put_response({ :ok, @ok_resp })

    result = Shopify.GraphQL.send("{ shop { name } }", http_client: Http.Mock, retry: Shopify.GraphQL.Retry.Linear)

    assert { :ok, %Response{} } = result
  end
end
