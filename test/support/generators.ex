defmodule Shopify.GraphQL.Generators do
  def gen_string(length \\ 4) do
    :crypto.strong_rand_bytes(4)
    |> Base.encode64()
    |> binary_part(0, length)
  end
end
