# Shopify.GraphQL

[![Actions Status](https://github.com/malomohq/shopify-graphql/workflows/ci/badge.svg)](https://github.com/malomohq/shopify-graphql/actions)

## Installation

`shopify_graphql` is published on [Hex](https://hex.pm/packages/shopify_graphql).
Add it to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:shopify_graphql, "~> 1.0"}
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
query =
  """
  {
    query GetCustomer($customerId: ID!) {
      customer(id:$customerId)
    }
  }
  """

query
|> Shopify.GraphQL.put_variable(:customerId, "gid://shopify/Customer/12195007594552")
|> Shopify.GraphQL.send()
```

## Configuration

Configuration is passed as a map to the second argument of `Shopify.GraphQL.send/2`.

* `:access_token` - Shopify access token for making authenticated requests
* `:endpoint` - endpoint for making GraphQL requests. Defaults to
                `graphql.json`.
* `:headers` - a list of additional headers to send when making a request.
               Example: `[{"x-graphql-cost-include-fields", "true"}]`. Defaults
               to `[]`.
* `:host` - HTTP host to make requests to. Defaults to `myshopify.com`. Note
            that using `:host` rather than a combination of `:host` and `:shop`
            may be more convenient when working with public apps.
* `:http_client` - the HTTP client used for making requests. Defaults to
                   `Shopify.GraphQL.Client.Hackney`.
* `:http_client_opts` - additional options passed to `:http_client`
* `:json_codec` - codec for encoding and decoding JSON payloads
* `:limiter` - whether to handle Shopify's rate limiting. When `false` a limiter
               will not be used. When `true` the process name used for the
               limiter will be `Shopify.GraphQL.Limiter`. If an atom is provided
               that will be provided as the process name for the limiter.
               Defaults to `false`. See the Rate Limiting section for more
               details.
* `:path` - path to the admin API. Defaults to `admin/api`.
* `:port` - the HTTP port used when making requests
* `:protocol` - the HTTP protocol when making requests. Defaults to `https`.
* `:shop` - name of the shop that a request is being made to
* `:version` - version of the API to use. Defaults to `2019-07`.
