defmodule Paginator.Cursor do
  @moduledoc false

  def decode(nil), do: nil

  def decode(encoded_cursor) do
    encoded_cursor
    |> Base.url_decode64!()
    |> safe_binary_to_term()
  end

  defp safe_binary_to_term(binary) do
    ensure_cursor_structs_loaded()

    cond do
      function_exported?(Plug.Crypto, :non_executable_binary_to_term, 2) ->
        Plug.Crypto.non_executable_binary_to_term(binary, [:safe])

      true ->
        :erlang.binary_to_term(binary, [:safe])
    end
  end

  defp ensure_cursor_structs_loaded do
    _ = Code.ensure_loaded(NaiveDateTime)
    _ = Code.ensure_loaded(Calendar.ISO)
  end

  def encode(values) when is_map(values) do
    values
    |> :erlang.term_to_binary()
    |> Base.url_encode64()
  end
end
