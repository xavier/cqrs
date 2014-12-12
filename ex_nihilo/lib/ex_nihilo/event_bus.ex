defmodule ExNihilo.EventBus do

  @name __MODULE__

  def start_link do
    :gen_event.start_link({:local, @name})
  end

  def add_listener(listener) do
    :gen_event.add_handler(@name, listener, [])
  end

  def remove_listener(listener) do
    :gen_event.delete_handler(@name, listener, [])
  end

  def listeners do
    :gen_event.which_handlers(@name)
  end

  def broadcast(uuid, event) do
    :gen_event.notify(@name, {event, uuid})
  end

  # Used for troubleshooting at this point
  def current_state(listener) do
    :gen_event.call(@name, listener, :current_state)
  end

end