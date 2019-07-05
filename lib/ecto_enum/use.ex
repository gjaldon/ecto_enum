defmodule EctoEnum.Use do
  @moduledoc false

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour Ecto.Type

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

      for {key, value} <- opts do
        string_key = Atom.to_string(key)
        def cast(unquote(key)), do: {:ok, unquote(key)}
        def cast(unquote(value)), do: {:ok, unquote(key)}
        def cast(unquote(string_key)), do: {:ok, unquote(key)}
      end

      def cast(_other), do: :error

      for {key, value} <- opts do
        string_key = Atom.to_string(key)
        def dump(unquote(key)), do: {:ok, unquote(value)}
        def dump(unquote(value)), do: {:ok, unquote(value)}
        def dump(unquote(string_key)), do: {:ok, unquote(value)}
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
