defmodule Shopify.GraphQL.Limiter.Consumer do
  use Task

  alias Shopify.GraphQL.{ Limiter, Request }

  @spec start_link(map) :: { :ok, pid }
  def start_link(event) do
    Task.start_link(__MODULE__, :send, [event])
  end

  @spec send(map) :: :ok
  def send(event) do
    config =  Map.get(event, :config)

    limiter_opts = Map.get(event, :limiter_opts)

    request = Map.get(event, :request)

    case Request.send(request, config) do
      { :ok, %{ body: %{ "errors" => [%{ "message" => "Throttled" }] } } = response } ->
        restore_to = Keyword.get(limiter_opts, :restore_to, :half)

        throttle_state = Limiter.ThrottleState.new(response)

        retry_in = Limiter.ThrottleState.throttle_for(throttle_state, restore_to)

        Limiter.Producer.wait_and_retry(event[:partition], event, retry_in)
      otherwise ->
        GenStage.reply(event[:owner], otherwise)
    end

    :ok
  end
end
