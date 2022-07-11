if Code.ensure_loaded?(GenStage) do
  defmodule Shopify.GraphQL.Limiter.Producer do
    use GenStage

    alias Shopify.GraphQL.{ Config, Helpers, Limiter, Request }

    #
    # client
    #

    @spec idle?(Limiter.name_t()) :: boolean
    def idle?(partition) do
      GenStage.call(name(partition), :idle?)
    end

    @spec name(Limiter.name_t()) :: Limiter.name_t()
    def name(partition) do
      Helpers.Limiter.process_name(partition, Producer)
    end

    @spec send(Limiter.name_t(), Request.t(), Config.t()) :: Shopify.GraphQL.http_response_t()
    def send(partition, request, config) do
      GenStage.call(name(partition), { :send, node(), request, config }, :infinity)
    end

    @spec start_link(Keyword.t()) :: GenServer.on_start()
    def start_link(opts) do
      GenStage.start_link(__MODULE__, opts, hibernate_after: 3_500, name: name(opts[:partition]))
    end

    @spec waiting?(Limiter.name_t()) :: boolean
    def waiting?(partition) do
      GenStage.call(name(partition), :waiting?)
    end

    @spec wait_and_retry(Limiter.name_t(), map, non_neg_integer) :: :ok
    def wait_and_retry(partition, event, wait_for) do
      GenStage.call(name(partition), { :wait_and_retry, event, wait_for })
    end

    #
    # callbacks
    #

    @impl true
    def init(opts) do
      state = Map.new()
      state = Map.put(state, :dead_owners, [])
      state = Map.put(state, :demand, 0)
      state = Map.put(state, :limiter_opts, opts[:limiter_opts])
      state = Map.put(state, :partition, opts[:partition])
      state = Map.put(state, :queue, :queue.new())
      state = Map.put(state, :waiting, false)

      Process.send_after(self(), :sweep_dead_owners, 5_000)

      { :producer, state }
    end

    @impl true
    def handle_call(:idle?, _from, state) do
      { :reply, :queue.is_empty(state[:queue]), [], state }
    end

    @impl true
    def handle_call({ :send, node, request, config }, { pid, _ref } = from, state) do
      Process.monitor(pid)

      event = Map.new()
      event = Map.put(event, :config, config)
      event = Map.put(event, :limiter_opts, state[:limiter_opts])
      event = Map.put(event, :partition, state[:partition])
      event = Map.put(event, :request, request)
      event = Map.put(event, :node, node)
      event = Map.put(event, :owner, from)

      queue = :queue.in(event, state[:queue])

      if state[:waiting] do
        { :noreply, [], %{ state | queue: queue } }
      else
        demand = Map.get(state, :demand)

        { { events, event_len }, queue } = Helpers.Queue.take(queue, demand)

        demand = demand - event_len

        { :noreply, events, %{ state | demand: demand, queue: queue } }
      end
    end

    @impl true
    def handle_call(:waiting?, _from, state) do
      { :reply, state[:waiting], [], state }
    end

    @impl true
    def handle_call({ :wait_and_retry, event, wait_for }, _from, state) do
      state[:timer] && Process.cancel_timer(state[:timer])

      dead_owners = Map.get(state, :dead_owners)

      { pid, _ } = event[:owner]

      alive? = !Enum.any?(dead_owners, fn({ dead_pid, _ }) -> dead_pid == pid end)

      queue = (alive? && :queue.in_r(event, state[:queue])) || state[:queue]

      state = Map.put(state, :queue, queue)
      state = Map.put(state, :timer, Process.send_after(self(), :start, wait_for))
      state = Map.put(state, :waiting, true)

      { :reply, :ok, [], state }
    end

    @impl true
    def handle_demand(demand, state) do
      demand = demand + Map.get(state, :demand, 3)

      if state[:waiting] do
        { :noreply, [], %{ state | demand: demand } }
      else
        { { events, event_len }, queue } = Helpers.Queue.take(state[:queue], demand)

        demand = demand - event_len

        { :noreply, events, %{ state | demand: demand, queue: queue } }
      end
    end

    @impl true
    def handle_info({ :DOWN, _ref, :process, pid, _reason }, state) do
      dead_owners = Map.get(state, :dead_owners)
      dead_owners = dead_owners ++ [{ pid, DateTime.utc_now() }]

      queue = Map.get(state, :queue)
      queue = :queue.delete_with(fn(%{ owner: { owner, _ } }) -> owner == pid end, queue)

      { :noreply, [], %{ state | dead_owners: dead_owners, queue: queue } }
    end

    @impl true
    def handle_info(:start, state) do
      demand = Map.get(state, :demand)

      { { events, event_len }, queue } = Helpers.Queue.take(state[:queue], demand)

      demand = demand - event_len

      state = Map.put(state, :demand, demand)
      state = Map.put(state, :queue, queue)
      state = Map.put(state, :timer, nil)
      state = Map.put(state, :waiting, false)

      { :noreply, events, state }
    end

    def handle_info(:sweep_dead_owners, state) do
      now = DateTime.utc_now()

      dead_owners = Map.get(state, :dead_owners)
      dead_owners = Enum.drop_while(dead_owners, fn({ _, time_of_death }) -> DateTime.diff(now, time_of_death) >= 45 end)

      Process.send_after(self(), :sweep_dead_owners, 5_000)

      { :noreply, [], %{ state | dead_owners: dead_owners } }
    end
  end
end
