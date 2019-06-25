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
