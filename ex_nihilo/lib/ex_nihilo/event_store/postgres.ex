defmodule ExNihilo.EventStore.Postgres do

  #
  # CREATE TABLE events(
  #   id SERIAL,
  #   uuid CHAR(36),
  #   event VARCHAR,
  #   payload TEXT
  # );
  # CREATE INDEX index_events_on_id ON events (id);
  # CREATE INDEX index_events_on_uuid ON events (uuid);
  #
  #

  def init([]) do
    # FIXME we need a way to pass options to the event store backend
    init([hostname: "localhost", username: "xavier", password: "", database: "cqrs_development"])
  end

  def init(conn_opts) do
    Postgrex.Connection.start_link(conn_opts)
  end

  def store(pg, uuid, {event, payload}) do
    params = [uuid, serialize_event(event), serialize_payload(payload)]
    sql = "INSERT INTO events (uuid, event, payload) VALUES ($1, $2, $3)"
    {status, res} = Postgrex.Connection.query(pg, sql, params)
    {status, pg}
  end

  def fetch(pg, uuid) do
    sql = "SELECT event, payload FROM events WHERE uuid = $1 ORDER BY id ASC"
    params = [uuid]
    case Postgrex.Connection.query(pg, sql, params) do
      {:ok, result} -> {:ok, process_result(result)}
      {status, _}   -> {status, []}
    end
  end

  def process_result(%{command: :select, rows: rows}) do
    Enum.map(rows, fn ({event, payload}) ->
      {deserialize_event(event), deserialize_payload(payload)}
    end)
  end

  #
  # Serialization
  #

  defp serialize_event(event),    do: Atom.to_string(event)
  defp deserialize_event(string), do: String.to_atom(string)

  defp serialize_payload(payload), do: JSON.encode!(payload)
  defp deserialize_payload(json),  do: JSON.decode!(json) |> atomize_keys

  defp atomize_keys(map), do: Enum.into(map, Map.new, &atomize_key/1)

  defp atomize_key({k, v}) when is_map(v), do: {String.to_atom(k), atomize_keys(v)}
  defp atomize_key({k, v}),                do: {String.to_atom(k), v}

end