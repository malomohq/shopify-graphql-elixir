# Shopify.GraphQL

## Installation

`shopify_graphql` is published on [Hex](https://hex.pm/packages/shopify_graphql).
Add it to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:shopify_graphql, "~> 0.1"}
  ]
end
```

You are also required to specify an HTTP client and JSON codec as dependencies.
`shopify_graphql` supports `:hackney` and `:jason` out of the box.

## Usage

You can make a request to the Shopify GraphQL admin API by passing a query to
the `Shopify.GraphQL.send/2` function.

```elixir
query =
  """
  {
    shop {
      name
    }
  }
  """

Shopify.GraphQL.send(query)
```

You can manage variables using the `Shopify.GraphQL.put_variable/3` function.

```elixir
operation =
  """
  {
    query GetCustomer($customerId: ID!) {
      customer(id:$customerId)
    }
  }
  """
  |> Shopify.GraphQL.put_variable(:customerId, "gid://shopify/Customer/12195007594552")
  |> Shopify.GraphQL.send()
```

## Configuration

You can provide application level configuration in `config.exs` using the
`:shopify_graphql` key.

```
config :shopify_graphql,
         access_token: "xxx",
         shop: "johns-apparel"
```

Additionally, you may pass an optional map to `Shopify.GraphQL.send/2` for
per-request configuration.

``` elixir
Shopify.GraphQL.send(query, %{ access_token: "xxx", shop: "johns-apparel" })
```

### Configuration Options

* `:access_token` - Shopify access token for making authenticated requests
* `:endpoint` - endpoint for making GraphQL requests. Defaults to
                `graphql.json`.
* `:host` - HTTP host to make requests to. Defaults to `myshopify.com`. Note
            that using `:host` rather than a combination of `:host` and `:shop`
            may be more convenient when working with public apps.
* `:http_client` - the HTTP client used for making requests. Defaults to
                   `Shopify.GraphQL.Client.Hackney`.
* `:http_client_opts` - additional options passed to `:http_client`
* `:json_codec` - codec for encoding and decoding JSON payloads
* `:path` - path to the admin API. Defaults to `admin/api`.
* `:port` - the HTTP port used when making requests
* `:protocol` - the HTTP protocol when making requests. Defaults to `https`.
* `:shop` - name of the shop that a request is being made to
* `:version` - version of the API to use. Defaults to `2019-04`.
