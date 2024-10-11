# Shopify.GraphQL

[![Actions Status](https://github.com/malomohq/shopify-graphql-elixir/workflows/ci/badge.svg)](https://github.com/malomohq/shopify-graphql-elixir/actions)

## Installation

`shopify_graphql` is published on [Hex](https://hex.pm/packages/shopify_graphql).
Add it to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:shopify_graphql, "~> 2.1.0"}
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

Shopify.GraphQL.send(query, access_token: "...", shop: "myshop"))
```

You can manage variables using the `Shopify.GraphQL.put_variable/3` and 
`Shopify.GraphQL.put_variables/2` functions.

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
|> Shopify.GraphQL.send(access_token: "...", shop: "myshop")

query
|> Shopify.GraphQL.put_variables(%{customerId: "gid://shopify/Customer/12195007594552"})
|> Shopify.GraphQL.send(access_token: "...", shop: "myshop")
```

## Configuration

All configuration must be provided on a per-request basis as a keyword list to
the second argument of `Shopify.GraphQL.send/2`.

* `:access_token` - Shopify access token for making authenticated requests
* `:endpoint` - endpoint for making GraphQL requests. Defaults to
                `graphql.json`.
* `:http_client` - the HTTP client used for making requests. Defaults to
                   `Shopify.GraphQL.Client.Hackney`.
* `:http_client_opts` - additional options passed to `:http_client`. Defaults to
                        `[]`.
* `:http_headers` - a list of additional headers to send when making a request.
               Example: `[{"x-graphql-cost-include-fields", "true"}]`. Defaults
               to `[]`.
* `:http_host` - HTTP host to make requests to. Defaults to `myshopify.com`. Note
            that using `:host` rather than a combination of `:host` and `:shop`
            may be more convenient when working with public apps.
* `:http_path` - path to the admin API. Defaults to `admin/api`.
* `:http_port` - the HTTP port used when making requests
* `:http_protocol` - the HTTP protocol when making requests. Defaults to `https`.
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
    * `:monitor` - whether to monitor a limiter. When set to `true` the limiter
                   process will be stopped after a certain period of time of inactivity
                   in order to keep limiter process size to a minimum. When set
                   to `false` the limiter process will not stop and will stay
                   alive indefinitely. Default `true`.
    * `:monitor_timeout` - number of miliseconds to check for inactivity before
                           stopping a partition
    * `:restore_to` - the minimum cost to begin making requests again after
                    being throttled. Possible values are `:half`, `:max` or an
                    integer. Defaults to `:half`.
* `:retry` - module implementing a strategy for retrying requests. Disabled when
  set to `false`. Defaults to `false`
* `:retry_opts` - options for configuring retry behavior. Defaults to `[]`.
    * `:max_attempts` - the maximum number of retries. Defaults to `3`.
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
Shopify.GraphQL.send(query, access_token: "...", limiter: true, shop: "myshop")
```

If you named your process something other than `Shopify.GraphQL.Limiter` you
will need to pass the name of the process to the `:limiter` config option
instead of `true`.

## Retries

`shopify_graphql` has a built-in mechanism for retrying requests that either
return an HTTP status code of 500 or a client error. You can enabled retries
by providing a module that implements the `Shopify.GraphQL.Retry` behaviour to the
`:retry` option when calling `Shopify.GraphQL.send/2`.

Currently, `shopify_graphql` provides a `Shopify.GraphQL.Retry.Linear` strategy for
retrying requests. This strategy will automatically retry a request on a set
interval. You can configure the interval by adding `:retry_in` with the number
of milliseconds to wait before sending another request to the `:retry_opts`
option.

**Example**

```elixir
Shopify.GraphQL.send("{ shop { name } }", access_token: "...", retry: Shopify.GraphQL.Retry.Linear, retry_opts: [retry_in: 250], shop: "myshop")
```

The example above would retry a failed request after 250 milliseconds. By
default `Shopify.GraphQL.Retry.Linear` will retry a request immediately if
`:retry_in` has no value

## Connection Pooling

The out-of-the-box HTTP client, `Shopify.GraphQL.Client.Hackney`, uses hackney's `:default`
connection pool. This pool has a maxiumum of `50` connections. You can tell
`shopify_graphql` to use a different connection pool by specifying the pool name
under http_client_opts in the config.

**Example**

Start a new hackney pool in `application.ex` on application startup:

```
defmodule BigPool.Application do
  use Application

  def start(_type, _args) do
    children = [
      ...
      :hackney_pool.child_spec(:my_big_pool, max_connections: 1000)
      ...
    ]

    opts = [strategy: :one_for_one, name: BigPool.Supervisor]
    _result = Supervisor.start_link(children, opts)
  end
end
```

And then specify the new pool name in the request config:

```
config = [
  ...
  http_client_opts: [pool: :my_big_pool]
  ...
]

query =
  """
  {
    shop {
      name
    }
  }
  """

Shopify.GraphQL.send(query, config)

```

