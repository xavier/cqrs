defmodule ExNihilo.DomainRepository do

  alias ExNihilo.EventStore, as: EventStore
  alias ExNihilo.EventBus,   as: EventBus

  def trigger(entity, event) do
    entity = apply_event(entity, event)
    store_event(entity.uuid, event)
    broadcast_event(entity.uuid, event)
    entity
  end

  def apply_event(entity, event) do
    entity.__struct__.apply(entity, event)
  end

  defp store_event(uuid, event) do
    EventStore.store(uuid, event)
  end

  defp broadcast_event(uuid, event) do
    EventBus.broadcast(uuid, event)
  end

  def get(mod, uuid) do
    EventStore.fetch(uuid)
    |> Enum.reduce(mod.new, &apply_event(&2, &1))
  end

end
