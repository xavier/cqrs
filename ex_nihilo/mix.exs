defmodule ExNihilo.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_nihilo,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger],
     mod: {ExNihilo, storage: storage()}]
  end

  defp storage do
    "EVENT_STORE"
    |> System.get_env
    |> storage
  end

  defp storage("ets"),    do: ExNihilo.EventStore.Ets
  defp storage("mnesia"), do: ExNihilo.EventStore.Mnesia
  defp storage("riak"),   do: ExNihilo.EventStore.Riak
  defp storage(_),        do: ExNihilo.EventStore.InMemory


  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    []
  end
end
