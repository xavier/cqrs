defmodule ExNihilo.EventStore do

  def start_link(backend, backend_opts) do
    Agent.start_link(fn ->
      {:ok, backend_state} = backend.init(backend_opts)
      {backend, backend_state}
    end, name: __MODULE__)
  end

  def store(uuid, event) do
    Agent.update(__MODULE__, fn ({backend, backend_state}) ->
      {:ok, backend_state} = backend.store(backend_state, uuid, event)
      {backend, backend_state}
    end)
  end

  def fetch(uuid) do
    # FIXME The agent API assumes that get has no side-effect on the state which
    # may not be true if the state is a connection object or something, the backend
    # may have to manage its own state itself, or we get rid of the agent and use
    # a custom GenServer where we can keep track of the an updated backend state
    Agent.get(__MODULE__, fn ({backend, backend_state}) ->
      {:ok, events} = backend.fetch(backend_state, uuid)
      events
    end)
  end

end