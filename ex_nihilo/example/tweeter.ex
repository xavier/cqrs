
defmodule Tweeter do

  defmodule User do

    use ExNihilo.Entity, fields: [followers: []]

    def create(uuid, name) do
      event = {:user_created, %{uuid: uuid, name: name}}
      user = new()
      trigger(user, event)
    end

    def rename(user, new_name) do
      event = {:user_renamed, %{name: new_name}}
      trigger(user, event)
    end

    def start_following(user, followed_user) do
      event = {:user_started_following, %{followed_user_uuid: followed_user.uuid}}
      user = trigger(user, event)
    end

    def add_follower(user, follower_user) do
      event = {:user_followed, %{follower_user_uuid: follower_user.uuid}}
      user = trigger(user, event)
    end

    def send_tweet(user, text) do
      event = {:user_tweeted, %{text: text}}
      user = trigger(user, event)
      fan_out_tweet_to_followers(user.followers, %{sender_uuid: user.uuid, text: text})
      user
    end

    def receive_tweet(user, tweet) do
      trigger(user, {:user_received_tweet, tweet})
    end

    defp fan_out_tweet_to_followers(followers, tweet) do
      followers
      |> Enum.map(fn (follower_uuid) -> Tweeter.User.get(follower_uuid) end)
      |> Enum.each(fn (follower) -> Tweeter.User.receive_tweet(follower, tweet) end)
    end

    def apply(user, {:user_created, %{uuid: uuid}}) do
      %{user | uuid: uuid}
    end

    def apply(user, {:user_followed, %{follower_user_uuid: follower_user_uuid}}) do
      %{user | followers: [follower_user_uuid | user.followers]}
    end

    def apply(user, ignored_event) do
      IO.puts "User #{user.uuid} ignored event: #{inspect ignored_event}"
      user
    end

  end

  defmodule Following do

    def start(user, followed_user) do
      {Tweeter.User.start_following(user, followed_user), Tweeter.User.add_follower(followed_user, user)}
    end

  end


  defmodule Projections do

    defmodule Users do
      use GenEvent

      def find_all do
        ExNihilo.EventBus.call(__MODULE__, :find_all)
      end

      def find_by_uuid(uuid) do
        ExNihilo.EventBus.call(__MODULE__, {:find_by_uuid, uuid})
      end

      def find_by_name(name) do
        ExNihilo.EventBus.call(__MODULE__, {:find_by_name, name})
      end

      ### GenEvent callbacks

      def init(_opts) do
        {:ok, HashDict.new}
      end

      def handle_event({{:user_created, %{name: name}}, uuid} = event, users) do
        {:ok, Dict.put_new(users, uuid, {uuid, name})}
      end

      def handle_event({{:user_renamed, %{name: name}}, uuid} = event, users) do
        {:ok, Dict.put(users, uuid, {uuid, name})}
      end

      def handle_event(_, _state) do
        {:ok, _state}
      end

      def handle_call(:find_all, users) do
        {:ok, users, users}
      end

      def handle_call({:find_by_uuid, uuid}, users) do
        {:ok, users[uuid], users}
      end

      def handle_call({:find_by_name, name}, users) do
        user = users
               |> Dict.values
               |> Enum.find(fn ({_, user_name}) -> user_name == name end)
        {:ok, user, users}
      end

    end

    defmodule Timeline do
      use GenEvent

      def for_user(uuid) do
        ExNihilo.EventBus.call(__MODULE__, {:for_user, uuid}) |> Enum.reverse
      end

      ### GenEvent callbacks

      def init(_opts) do
        {:ok, HashDict.new}
      end

      def handle_event({{:user_received_tweet, %{sender_uuid: _, text: text}}, uuid} = event, timelines) do
        {:ok, Dict.update(timelines, uuid, [text], fn (timeline) -> [text|timeline] end)}
      end

      def handle_event(_, _state) do
        {:ok, _state}
      end

      def handle_call({:for_user, uuid}, timelines) do
        {:ok, timelines[uuid] || [], timelines}
      end

    end

  end

end

ExNihilo.EventBus.add_listener(Tweeter.Projections.Users)
ExNihilo.EventBus.add_listener(Tweeter.Projections.Timeline)

julien = Tweeter.User.create(ExNihilo.UUID.generate, "Julien")

xavier = Tweeter.User.create(ExNihilo.UUID.generate, "Xavier")
alice = Tweeter.User.create(ExNihilo.UUID.generate, "Alice")
bob = Tweeter.User.rename(alice, "Bob")

{xavier, julien} = Tweeter.Following.start(xavier, julien)

IO.inspect xavier
IO.inspect julien

Tweeter.User.send_tweet(julien, "Hello World!")
Tweeter.User.send_tweet(julien, "My 2nd tweet!")
Tweeter.User.send_tweet(julien, "My 3rd tweet! Yay!")

IO.inspect Tweeter.Projections.Timeline.for_user(julien.uuid)
IO.inspect Tweeter.Projections.Timeline.for_user(xavier.uuid)

# IO.inspect julien
# IO.inspect xavier

# IO.inspect Tweeter.Projections.Users.find_all
# IO.inspect Tweeter.Projections.Users.find_by_uuid(alice.uuid)
# IO.inspect Tweeter.Projections.Users.find_by_uuid("bogus")
# IO.inspect Tweeter.Projections.Users.find_by_name("Bob")
