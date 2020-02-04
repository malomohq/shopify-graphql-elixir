# Shopify.GraphQL

[![Actions Status](https://github.com/malomohq/shopify-graphql-elixir/workflows/ci/badge.svg)](https://github.com/malomohq/shopify-graphql-elixir/actions)

## Installation

`shopify_graphql` is published on [Hex](https://hex.pm/packages/shopify_graphql).
Add it to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:shopify_graphql, "~> 1.3"}
  ]
end
```

You are also required to specify an HTTP client and JSON codec as dependencies.
`shopify_graphql` supports `hackney` and `jason` out of the box.

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
* `:http_client_opts` - additional options passed to `:http_client`. Defaults to
                        `[]`.
* `:json_codec` - codec for encoding and decoding JSON payloads
* `:limiter` - whether to use the limiter to manage Shopify rate limiting. May
               be `true`, `false` or an atom. If `false` the limiter will not
               be used. If `true` the limiter will be used and the default
               name `Shopify.GraphQL.Limiter` will be used to interact with the
               limiter process. If an atom is used the limiter will be used and
               the atom will be used to interact with the limiter process.
               Defaults to `false`.
* `:limiter_opts` - additional options used with `:limiter`. Defaults to `[]`.
    * `:max_requests` - the maximum number of concurrent requests per shop.
                      Defaults to 3.
    * `:restore_to` - the minimum cost to begin making requests again after
                    being throttled. Possible values are `:half`, `:max` or an
                    integer. Defaults to `:half`.
* `:path` - path to the admin API. Defaults to `admin/api`.
* `:port` - the HTTP port used when making requests
* `:protocol` - the HTTP protocol when making requests. Defaults to `https`.
* `:retry` - whether to automatically retry failed API calls. Maybe be `true` or
             `false`. Defaults to `false`.
* `:retry_opts` - additional options used when performing retries. Defaults to
                  `[]`.
    * `:max_attempts` - the maximum number of retries to make. Defaults to 3.
* `:shop` - name of the shop that a request is being made to
* `:version` - version of the API to use. Defaults to `nil`. According to
  Shopify, when not specifying a version Shopify will use the oldest stable
  version of its API.

## Rate Limiting

`shopify_graphql` provides the ability to automatically manage the rate limiting
of Shopify's GraphQL admin API. We do this using what's called a limiter. The
limiter will automatically detect when queries are being rate limited and begin
managing the traffic sent to Shopify to ensure queries get executed.

The limiter is an optional feature of `shopify_graphql`. To use it you will
need to add `gen_stage` as a dependency to your application.

You will then need to add `Shopify.GraphQL.Limiter` to your supervision tree.
When starting the limiter you may optionally pass a `:name` argument. If the
`:name` argument is used the process will use that value as it's name.

To send queries through the limiter you will need to pass the `limiter: true`
config value to `Shopify.GraphQL.send/2`.

### Example

```elixir
Shopify.GraphQL.send(query, %{access_token: "...", limiter: true})
```

If you named your process something other than `Shopify.GraphQL.Limiter` you
will need to pass the name of the process to the `:limiter` config option
instead of `true`.
