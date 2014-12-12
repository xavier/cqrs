defmodule ExNihilo.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      worker(ExNihilo.EventStore, [ExNihilo.EventStore.InMemory, []]),
      worker(ExNihilo.EventBus, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one]

    supervise(children, opts)
  end

end
