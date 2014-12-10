# <framework code>

defmodule UniqueID do
  def generate do
    Kernel.make_ref()
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
    entity
  end

  def apply_event(entity, event) do
    entity.__struct__.apply(entity, event)
  end

  defp store_event(uuid, event) do
    EventStore.store(uuid, event)
  end

  def get(mod, uuid) do
    EventStore.fetch(uuid)
    |> Enum.reduce(mod.new, &apply_event(&2, &1))
  end

end


defmodule Entity do

  defmacro __using__(fields: fields) do

    fields = [ {:uuid, nil} | fields]

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

    def create do
      uuid = UniqueID.generate
      {uuid, create(uuid)}
    end


    def add_item(cart, item) do
      event = {:item_added, %{item: item}}
      trigger(cart, event)
    end

    def apply(cart, {:cart_created, %{uuid: uuid}}) do
      %{cart | uuid: uuid}
    end

    def apply(cart, {:item_added, %{item: item}}) do
      %{cart | items: [item|cart.items]}
    end

  end


  defmodule User do

    use Entity, fields: [name: nil, age: 0, wizard: false]

    def create(uuid, name, age, wizard) do
      event = {:user_created, %{uuid: uuid, name: name, age: age, wizard: wizard}}
      user = new()
      trigger(user, event)
    end

    def create(name, age, wizard) do
      uuid = UniqueID.generate
      {uuid, create(uuid, name, age, wizard)}
    end

    def changed_name(user, new_name) do
      event = {:changed_name, %{new_name: new_name}}
      trigger(user, event)
    end

    def birthday(user) do
      event = {:birthday}
      trigger(user, event)
    end

    def graduated_from_hogwarts(user) do
      event = {:graduated_from_hogwarts}
      trigger(user, event)
    end


    def apply(user, {:user_created, opts}) do
      %{user | uuid: opts.uuid, name: opts.name, age: opts.age, wizard: opts.wizard}
    end

    def apply(user, {:changed_name, %{new_name: new_name}}) do
      %{user | name: new_name }
    end

    def apply(user, {:birthday}) do
      %{user | age: user.age + 1 }
    end

    def apply(user, {:graduated_from_hogwarts}) do
      %{user | wizard: true }
    end



  end

end

EventStore.start_link

{cart_uuid, cart} = PotionStore.ShoppingCart.create

cart = cart
      |> PotionStore.ShoppingCart.add_item("Artline 100N")
      |> PotionStore.ShoppingCart.add_item("Coke classic")
      |> PotionStore.ShoppingCart.add_item("Coke zero")
IO.inspect cart

IO.puts "====================="

cart = PotionStore.ShoppingCart.get(cart_uuid)
IO.inspect cart

IO.puts "##################"


{user_uuid, user} = PotionStore.User.create("Harry Porter", 17, false)

user = user
      |> PotionStore.User.changed_name("Harry Potter")
      |> PotionStore.User.birthday
      |> PotionStore.User.graduated_from_hogwarts

IO.inspect user

IO.puts "====================="

user = PotionStore.User.get(user_uuid)
IO.inspect user

