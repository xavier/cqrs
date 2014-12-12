defmodule ExNihilo do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, [storage: storage]) do
    ExNihilo.Supervisor.start_link(storage)
  end
end
