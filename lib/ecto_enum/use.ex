defmodule EctoEnum.Use do
  @moduledoc false

  alias EctoEnum.Typespec

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      [h | _t] = opts

      opts =
        cond do
          Keyword.keyword?(opts) ->
            opts

          is_binary(h) ->
            Enum.map(opts, fn value -> {String.to_atom(value), value} end)

          true ->
            raise "Enum must be a keyword list or a list of strings"
        end

      typespec = Typespec.make(Keyword.keys(opts))

      @behaviour Ecto.Type

      @type t :: unquote(typespec)

      keys = Keyword.keys(opts)
      string_keys = Enum.map(keys, &Atom.to_string/1)
      @valid_values Enum.uniq(keys ++ string_keys ++ Keyword.values(opts))

      {_key, value} = opts |> hd()

      type =
        if is_integer(value) do
          :integer
        else
          :string
        end

      def type, do: unquote(type)

      for {key, value} <- opts, k <- Enum.uniq([key, value, Atom.to_string(key)]) do
        def cast(unquote(k)), do: {:ok, unquote(key)}
      end

      def cast(_other), do: :error

      for {key, value} <- opts, k <- Enum.uniq([key, value, Atom.to_string(key)]) do
        def cast!(unquote(k)), do: unquote(key)
      end

      def cast!(other), do: raise Ecto.CastError, type: __MODULE__, value: other

      for {key, value} <- opts, k <- Enum.uniq([key, value, Atom.to_string(key)]) do
        def dump(unquote(k)), do: {:ok, unquote(value)}
      end

      def dump(term) do
        msg =
          "Value `#{inspect(term)}` is not a valid enum for `#{inspect(__MODULE__)}`. " <>
            "Valid enums are `#{inspect(__valid_values__())}`"

        raise Ecto.ChangeError, message: msg
      end

      for {key, value} <- opts, k <- Enum.uniq([key, value, Atom.to_string(key)]) do
        def dump!(unquote(k)), do: unquote(value)
      end

      def dump!(term) do
        msg =
          "Value `#{inspect(term)}` is not a valid enum for `#{inspect(__MODULE__)}`. " <>
            "Valid enums are `#{inspect(__valid_values__())}`"

        raise Ecto.ChangeError, message: msg
      end

      def embed_as(_), do: :self

      def equal?(term1, term2), do: term1 == term2

      for {key, value} <- opts do
        def load(unquote(value)), do: {:ok, unquote(key)}
      end

      def valid_value?(value) do
        Enum.member?(@valid_values, value)
      end

      # # Reflection
      def __enum_map__(), do: unquote(opts)
      def __valid_values__(), do: @valid_values
    end
  end
end
