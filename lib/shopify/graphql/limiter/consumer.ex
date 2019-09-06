defmodule Shopify.GraphQL.Limiter.Consumer do
  use Task

  alias Shopify.GraphQL.{ Limiter }

  def start_link(event) do
    Task.start_link(__MODULE__, :run, [event])
  end

  def run(event) do
    owner = Map.get(event, :owner)
    producer = Map.get(event, :producer)

    { operation, config } = Map.get(event, :request)

    case Shopify.GraphQL.send(operation, config) do
      { :ok, %{ body: %{ "errors" => [%{ "message" => "Throttled" }] } } = response} ->
        throttle_state = Limiter.ThrottleState.from_response(response)
        
        Limiter.Producer.throttle(producer)
        Limiter.Producer.retry(producer, operation, config)
        Limiter.Producer.drain(producer, throttle_state)
      otherwise ->
        GenStage.reply(owner, otherwise)
    end
  end
end
