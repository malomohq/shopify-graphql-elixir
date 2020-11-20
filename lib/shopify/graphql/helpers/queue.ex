defmodule Shopify.GraphQL.Helpers.Queue do
  @spec take(:queue.queue, non_neg_integer) :: { { list, non_neg_integer }, :queue.queue }
  def take(queue, n) do
    do_take(queue, :queue.new(), 0, n)
  end

  defp do_take(queue, acc, acc_len, 0) do
    { { :queue.to_list(acc), acc_len }, queue }
  end

  defp do_take(queue, acc, acc_len, n) do
    case :queue.out(queue) do
      { { :value, item }, queue } ->
        do_take(queue, :queue.in(item, acc), acc_len + 1, n - 1)
      { :empty, queue } ->
        { { :queue.to_list(acc), acc_len }, queue }
    end
  end
end
