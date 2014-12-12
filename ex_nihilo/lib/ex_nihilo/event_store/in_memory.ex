defmodule ExNihilo.EventStore.InMemory do

  def init(_opts) do
    {:ok, []}
  end

  def store(events, uuid, event) do
    {:ok, [{uuid, event} | events]}
  end

  def fetch(events, uuid) do
    fetched_events =
      events
      |> Enum.filter(fn {event_uuid, _event} -> event_uuid == uuid end)
      |> Enum.map(fn {_, event} -> event end)
      |> Enum.reverse
    {:ok, fetched_events}
  end

end