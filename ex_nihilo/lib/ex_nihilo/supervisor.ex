defmodule ExNihilo.Supervisor do
  use Supervisor

  def start_link(storage) do
    Supervisor.start_link(__MODULE__, [storage])
  end

  def init([storage]) do
    children = [
      worker(ExNihilo.EventStore, [storage, []]),
      worker(ExNihilo.EventBus, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one]

    supervise(children, opts)
  end

end
