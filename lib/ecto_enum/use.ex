defmodule EctoEnum.Use do
  @moduledoc false

  alias EctoEnum.Typespec

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
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
        def dump(unquote(k)), do: {:ok, unquote(value)}
      end

      def dump(term) do
        msg =
          "Value `#{inspect(term)}` is not a valid enum for `#{inspect(__MODULE__)}`. " <>
            "Valid enums are `#{inspect(__valid_values__())}`"

        raise Ecto.ChangeError, message: msg
      end

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
