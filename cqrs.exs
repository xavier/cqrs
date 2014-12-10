# <framework code>

defmodule UniqueID do

  @x           "~2.16.0b"
  @uuid_format "#{@x}#{@x}#{@x}#{@x}-#{@x}#{@x}-#{@x}#{@x}-#{@x}#{@x}-#{@x}#{@x}#{@x}#{@x}#{@x}#{@x}"

  def generate do
    random_bytes = :crypto.strong_rand_bytes(16) |> :erlang.bitstring_to_list
    :io_lib.format(@uuid_format, random_bytes) |> to_string
  end

end

defmodule EventBus do

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

defmodule EventStore do

  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def store(uuid, event) do
    Agent.update(__MODULE__, fn (events) ->
      [{uuid, event} | events]
    end)
  end

  def fetch(uuid) do
    Agent.get(__MODULE__, fn (events) ->
      events
      |> Enum.filter(fn {event_uuid, _event} -> event_uuid == uuid end)
      |> Enum.map(fn {_, event} -> event end)
      |> Enum.reverse
    end)
  end

end

defmodule DomainRepository do

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


defmodule Entity do

  defmacro __using__(fields: fields) do

    fields = [{:uuid, nil} | fields]

    quote do

      defstruct unquote(fields)

      def get(uuid) do
        DomainRepository.get(__MODULE__, uuid)
      end

      def new do
        %__MODULE__{}
      end

      def trigger(cart, event) do
        DomainRepository.trigger(cart, event)
      end

    end
  end

end

# </framework code>

defmodule PotionStore do
  defmodule ShoppingCart do

    use Entity, fields: [items: []]

    def create(uuid) do
      event = {:cart_created, %{uuid: uuid}}
      cart = new()
      trigger(cart, event)
    end

    def add_item(cart, item) do
      event = {:item_added, %{item: item}}
      trigger(cart, event)
    end

    def remove_item(cart, item) do
      event = {:item_removed, %{item: item}}
      trigger(cart, event)
    end

    def apply(cart, {:cart_created, %{uuid: uuid}}) do
      %{cart | uuid: uuid}
    end

    def apply(cart, {:item_added, %{item: item}}) do
      %{cart | items: [item|cart.items]}
    end

    def apply(cart, {:item_removed, %{item: item}}) do
      %{cart | items: List.delete(cart.items, item)}
    end
  end
end

# Listeners

defmodule CartItemCounter do
  use GenEvent

  def init(_opts) do
    {:ok, HashDict.new}
  end

  def handle_event({{:item_added, %{item: item}}, _uuid}, counters) do
    counters = Dict.update(counters, item, 1, fn(count) -> count + 1 end)
    {:ok, counters}
  end

  def handle_event({{:item_removed, %{item: item}}, _uuid}, counters) do
    counters = Dict.update!(counters, item, fn(count) -> count - 1 end)
    {:ok, counters}
  end

  def handle_event(_, counters) do
    {:ok, counters}
  end

  def handle_call(:current_state, counters) do
    {:ok, counters, counters}
  end

end

defmodule EventDebugger do
  use GenEvent

  def init(_opts) do
    {:ok, 0}
  end

  def handle_event({event, uuid}, counter) do
    counter = counter + 1
    IO.puts "EventDebugger: Event##{counter} #{inspect event}, UUID: #{inspect uuid}"
    {:ok, counter}
  end

end

EventStore.start_link
EventBus.start_link

EventBus.add_listener(CartItemCounter)
EventBus.add_listener(EventDebugger)

cart_uuid = UniqueID.generate

cart =
  PotionStore.ShoppingCart.create(cart_uuid)
  |> PotionStore.ShoppingCart.add_item("Artline 100N")
  |> PotionStore.ShoppingCart.add_item("Coke classic")
  |> PotionStore.ShoppingCart.add_item("Coke zero")

IO.inspect cart

IO.puts "====================="

cart = PotionStore.ShoppingCart.get(cart_uuid)
IO.inspect cart

IO.puts "====================="

cart2 =
  PotionStore.ShoppingCart.create(UniqueID.generate)
  |> PotionStore.ShoppingCart.add_item("Coke classic")
  |> PotionStore.ShoppingCart.add_item("Coke classic")
  |> PotionStore.ShoppingCart.add_item("Doppio espresso")
  |> PotionStore.ShoppingCart.remove_item("Coke classic")

IO.inspect cart2

counter = EventBus.current_state(CartItemCounter)
IO.puts "Items currently added to carts: #{inspect counter}"
