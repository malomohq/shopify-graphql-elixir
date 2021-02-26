defmodule Shopify.GraphQL.Http.Mock do
  @behaviour Shopify.GraphQL.Http

  use GenServer

  @proc_key :__shopify_graphql_http_mock__

  #
  # client
  #

  def start_link do
    { :ok, pid } = GenServer.start_link(__MODULE__, :ok)

    Process.put(@proc_key, pid)

    { :ok, pid }
  end

  def get_request_body do
    pid = Process.get(@proc_key)

    GenServer.call(pid, :get_request_body)
  end

  def get_request_headers do
    pid = Process.get(@proc_key)

    GenServer.call(pid, :get_request_headers)
  end

  def get_request_method do
    pid = Process.get(@proc_key)

    GenServer.call(pid, :get_request_method)
  end

  def get_request_url do
    pid = Process.get(@proc_key)

    GenServer.call(pid, :get_request_url)
  end

  def put_response(response) do
    pid = Process.get(@proc_key)

    GenServer.call(pid, { :put_response, response })
  end

  @impl true
  def send(request, _opts) do
    pid = Process.get(@proc_key)

    :ok = GenServer.call(pid, { :put_request_method, request.method })
    :ok = GenServer.call(pid, { :put_request_url, request.url })
    :ok = GenServer.call(pid, { :put_request_headers, request.headers })
    :ok = GenServer.call(pid, { :put_request_body, request.body })

    GenServer.call(pid, :get_response)
  end

  #
  # callbacks
  #

  @impl true
  def init(:ok) do
    { :ok, %{} }
  end

  @impl true
  def handle_call(:get_request_body, _from, state) do
    { :reply, Map.fetch!(state, :request_body), state }
  end

  @impl true
  def handle_call(:get_request_headers, _from, state) do
    { :reply, Map.fetch!(state, :request_headers), state }
  end

  @impl true
  def handle_call(:get_request_method, _from, state) do
    { :reply, Map.fetch!(state, :request_method), state }
  end

  @impl true
  def handle_call(:get_request_url, _from, state) do
    { :reply, Map.fetch!(state, :request_url), state }
  end

  @impl true
  def handle_call(:get_response, _from, state) do
    [h | t] = Map.get(state, :responses, [])

    { :reply, h, Map.put(state, :responses, t) }
  end

  @impl true
  def handle_call({ :put_request_body, body }, _from, state) do
    { :reply, :ok, Map.put(state, :request_body, body) }
  end

  @impl true
  def handle_call({ :put_request_headers, headers }, _from, state) do
    { :reply, :ok, Map.put(state, :request_headers, headers) }
  end

  @impl true
  def handle_call({ :put_request_method, method }, _from, state) do
    { :reply, :ok, Map.put(state, :request_method, method) }
  end

  @impl true
  def handle_call({ :put_request_url, url }, _from, state) do
    { :reply, :ok, Map.put(state, :request_url, url) }
  end

  @impl true
  def handle_call({ :put_response, response }, _from, state) do
    responses = Map.get(state, :responses, [])
    responses = responses ++ [response]

    { :reply, :ok, Map.put(state, :responses, responses) }
  end
end
