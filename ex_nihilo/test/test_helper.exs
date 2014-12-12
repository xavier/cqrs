ExUnit.start()

defmodule PotionStore do
  defmodule ShoppingCart do

    use ExNihilo.Entity, fields: [items: []]

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
      %{cart | items: cart.items ++ [item]}
    end

    def apply(cart, {:item_removed, %{item: item}}) do
      %{cart | items: List.delete(cart.items, item)}
    end
  end

end