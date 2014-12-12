
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


defmodule ExNihiloTest do
  use ExUnit.Case

  test "the truth" do
    ExNihilo.EventBus.add_listener(CartItemCounter)
    ExNihilo.EventBus.add_listener(EventDebugger)

    cart_uuid = ExNihilo.UUID.generate

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
      PotionStore.ShoppingCart.create(ExNihilo.UUID.generate)
      |> PotionStore.ShoppingCart.add_item("Coke classic")
      |> PotionStore.ShoppingCart.add_item("Coke classic")
      |> PotionStore.ShoppingCart.add_item("Doppio espresso")
      |> PotionStore.ShoppingCart.remove_item("Coke classic")

    IO.inspect cart2

    counter = ExNihilo.EventBus.current_state(CartItemCounter)
    IO.puts "Items currently added to carts: #{inspect counter}"

    # TODO make sure we execute this even if test fails
    ExNihilo.EventBus.remove_listener(CartItemCounter)
    ExNihilo.EventBus.remove_listener(EventDebugger)
  end
end
