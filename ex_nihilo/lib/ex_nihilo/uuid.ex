defmodule ExNihilo.UUID do

  @x           "~2.16.0b"
  @uuid_format "#{@x}#{@x}#{@x}#{@x}-#{@x}#{@x}-#{@x}#{@x}-#{@x}#{@x}-#{@x}#{@x}#{@x}#{@x}#{@x}#{@x}"

  def generate do
    random_bytes = :crypto.strong_rand_bytes(16) |> :erlang.bitstring_to_list
    :io_lib.format(@uuid_format, random_bytes) |> to_string
  end

end
