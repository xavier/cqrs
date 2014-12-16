defmodule ProjectionTest do
  use ExUnit.Case, async: true

  alias ExNihilo.UUID
  alias PotionStore.ShoppingCart

  defmodule CartValue do

    #
    # TODO
    #

    def project(event_stream) do
      event_stream |> Enum.reduce(initial_value, &process/2)
    end

    def initial_value do
      0
    end

    defp process({{:item_added, _}, _}, count) do
      count + 1
    end

    defp process({{:item_removed, _}, _}, count) do
      count - 1
    end

  end

  test "projection" do

    uuid_cart1 = UUID.generate
    uuid_cart2 = UUID.generate
    uuid_cart3 = UUID.generate

    events = [
      {{:item_added,   "Foo"}, uuid_cart1},
      {{:item_added,   "Baz"}, uuid_cart1},
      {{:item_added,   "Foo"}, uuid_cart2},
      {{:item_removed, "Baz"}, uuid_cart1},
      {{:item_added,   "Bar"}, uuid_cart2},
      {{:item_added,   "Bar"}, uuid_cart3},
      {{:item_added,   "Baz"}, uuid_cart3},
    ]

    assert 5 == CartValue.project(events)

  end

end
