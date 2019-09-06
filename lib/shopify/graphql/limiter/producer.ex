defmodule Shopify.GraphQL.Limiter.Producer do
  use GenStage

  alias Shopify.GraphQL.{ Helpers }

  #
  # client
  #

  @doc """
  Returns the number of events queued by a producer.
  """
  @spec count(GenStage.stage()) :: non_neg_integer
  def count(server) do
    GenStage.call(server, :count)
  end

  @doc """
  Begins the drain process.
  """
  @spec drain(GenStage.stage(), Shopify.GraphQL.Limiter.ThrottleState.t()) :: :ok
  def drain(server, throttle_state) do
    GenStage.call(server, { :drain, throttle_state })
  end

  @doc """
  Returns whether the producer is currently waiting for a shop's cost bucket to
  drain.
  """
  @spec draining?(GenStage.stage()) :: boolean
  def draining?(server) do
    GenStage.call(server, :draining?)
  end

  @doc """
  Determines whether a producer is in an idle state.

  A producer is considered idle when it's queue length is 0.
  """
  @spec idle?(GenStage.stage()) :: boolean
  def idle?(server) do
    GenStage.call(server, :idle?)
  end

  @doc """
  Returns the name of a `Shopify.GraphQL.Limiter.Producer` process.

  A producer process's name is a combination of the parent limiter's name
  and a partition id. e.g. `Shopify.GraphQL.Limiter.Producer:<partition_id>`.
  """
  @spec name(atom, Shopify.GraphQL.Limiter.partition_id_t()) :: atom
  def name(parent, partition_id) do
    Module.concat([parent, "Producer:#{partition_id}"])
  end

  @doc """
  Synchronously processes a request.
  """
  @spec process(GenStage.stage(), Shopify.GraphQL.Operation.t(), Shopify.GraphQL.Config.t()) :: Shopify.GraphQL.response_t()
  def process(server, operation, config) do
    GenStage.call(server, { :process, { operation, config }, false }, :infinity)
  end

  @doc """
  """
  @spec restore(GenStage.stage()) :: :ok
  def restore(server) do
    GenStage.cast(server, :restore)
  end

  @spec retry(GenStage.stage(), Shopify.GraphQL.Operation.t(), Shopify.GraphQL.Config.t()) :: :ok
  def retry(server, operation, config) do
    GenStage.call(server, { :retry, { operation, config } })
  end

  @doc """
  Starts a `Shopify.GraphQL.Limiter.Producer` process and links it to the
  supervision tree.
  """
  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  @doc """
  Stops the producer from fulfilling demand.
  """
  @spec throttle(GenStage.stage()) :: :ok
  def throttle(server) do
    GenStage.call(server, :throttle)
  end

  @doc """
  Returns the throttle status.
  """
  @spec throttled?(GenStage.stage()) :: boolean
  def throttled?(server) do
    GenStage.call(server, :throttled?)
  end

  @doc """
  Starts demand fulfillment.
  """
  @spec unthrottle(GenStage.stage()) :: :ok
  def unthrottle(server) do
    GenStage.call(server, :unthrottle)
  end

  #
  # callbacks
  #

  @impl true
  def init(opts) do
    state =
      opts
      |> Keyword.take([:parent, :partition_id, :restore_to])
      |> Enum.into(%{})
      |> Map.put(:demand, 0)
      |> Map.put(:queue, :queue.new())
      |> Map.put(:queue_len, 0)
      |> Map.put(:throttled?, false)
      |> Map.put(:timer, nil)
      |> Map.put_new(:restore_to, :half)

    { :producer, state }
  end

  @impl true
  def handle_call({ :drain, throttle_state }, _from, state) do
    state = cancel_restore(state)

    min = Map.get(state, :restore_to)

    time_to_restore = Helpers.Limiter.time_to_restore(min, throttle_state)

    timer = Process.send_after(self(), :restore, time_to_restore)

    state = Map.put(state, :timer, timer)

    { :reply, :ok, [], state }
  end

  @impl true
  def handle_call(:draining?, _from, state) do
    draining? = Map.get(state, :timer) != nil

    { :reply, draining?, [], state }
  end

  @impl true
  def handle_call(:count, _from, state) do
    count = Map.get(state, :queue_len)

    { :reply, count, [], state }
  end

  @impl true
  def handle_call(:idle?, _from, state) do
    idle? = Map.get(state, :queue_len) == 0

    { :reply, idle?, [], state }
  end

  @impl true
  def handle_call({ :process, request, async }, from, state) do
    event = %{ owner: from, producer: self(), request: request }

    state = push(state, event)
    state = increment(state)

    { events, state } = fulfill(state)

    if async do
      { :reply, :ok, events, state }
    else
      { :noreply, events, state }
    end
  end

  def handle_call({ :retry, request }, from, state) do
    event = %{ owner: from, producer: self(), request: request }

    state = push_r(state, event)
    state = increment(state)

    { events, state } = fulfill(state)

    { :reply, :ok, events, state }
  end

  @impl true
  def handle_call(:throttle, _from, state) do
    state = Map.put(state, :throttled?, true)

    { :reply, :ok, [], state }
  end

  @impl true
  def handle_call(:throttled?, _from, state) do
    throttled? = Map.get(state, :throttled?)

    { :reply, throttled?, [], state }
  end

  @impl true
  def handle_call(:unthrottle, _from, state) do
    state = Map.put(state, :throttled?, false)

    { events, state } = fulfill(state)

    { :reply, :ok, events, state }
  end

  @impl true
  def handle_cast(:restore, state) do
    state = cancel_restore(state)
    state = Map.put(state, :throttled?, false)

    { events, state } = fulfill(state)

    { :noreply, events, state }
  end

  @impl true
  def handle_demand(demand, state) do
    state = Map.put(state, :demand, demand)

    { events, state } = fulfill(state)

    { :noreply, events, state }
  end

  @impl true
  def handle_info(:restore, state) do
    state = Map.put(state, :timer, nil)

    restore(self())

    { :noreply, [], state }
  end

  #
  # process
  #

  defp fulfill(state) do
    fulfill([], state)
  end

  defp fulfill(events, %{ demand: demand, queue_len: queue_len, throttled?: throttled } = state)
       when demand == 0 or queue_len == 0 or throttled == true
  do
    { events, state }
  end

  defp fulfill(events, state) do
    demand = Map.get(state, :demand)
    queue = Map.get(state, :queue)
    queue_len = Map.get(state, :queue_len)

    { { :value, event }, queue } = :queue.out(queue)

    state = Map.put(state, :demand, demand - 1)
    state = Map.put(state, :queue, queue)
    state = Map.put(state, :queue_len, queue_len - 1)

    fulfill(events ++ [event], state)
  end

  defp increment(state) do
    Map.put(state, :queue_len, Map.get(state, :queue_len) + 1)
  end

  defp push(state, event) do
    queue = Map.get(state, :queue)

    queue = :queue.in(event, queue)

    Map.put(state, :queue, queue)
  end

  defp push_r(state, event) do
    queue = Map.get(state, :queue)

    queue = :queue.in_r(event, queue)

    Map.put(state, :queue, queue)
  end

  #
  # drain
  #

  defp cancel_restore(%{ timer: nil } = state) do
    state
  end

  defp cancel_restore(state) do
    timer = Map.get(state, :timer)

    Process.cancel_timer(timer)

    Map.put(state, :timer, nil)
  end
end
