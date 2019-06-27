defmodule EctoEnum.Use do
  @moduledoc false

  defmacro __using__(opts) do
    quote do
      @behaviour Ecto.Type
      opts = unquote(opts)

      Module.put_attribute(__MODULE__, :kw, opts)

      @before_compile EctoEnum.Use

      keys = Keyword.keys(opts)
      string_keys = Enum.map(keys, &Atom.to_string/1)
      @valid_values keys ++ string_keys ++ Keyword.values(opts)

      {_key, value} = opts |> hd()

      type =
        if is_integer(value) do
          :integer
        else
          :string
        end

      @__type__ type

      def type, do: @__type__

      def valid_value?(value) do
        Enum.member?(@valid_values, value)
      end

      # # Reflection
      def __enum_map__(), do: @kw
      def __valid_values__(), do: @valid_values
    end
  end

  defmacro __before_compile__(env) do
    kw = Module.get_attribute(env.module, :kw)

    casts(kw) ++ dumps(kw) ++ loads(kw)
  end

  defp casts(kw) do
    casts =
      for {key, value} <- kw do
        string_key = Atom.to_string(key)

        quote do
          def cast(unquote(key)), do: {:ok, unquote(key)}
          def cast(unquote(value)), do: {:ok, unquote(key)}
          def cast(unquote(string_key)), do: {:ok, unquote(key)}
        end
      end

    cast =
      quote do
        def cast(_other), do: :error
      end

    casts ++ [cast]
  end

  defp dumps(kw) do
    dumps =
      for {key, value} <- kw do
        string_key = Atom.to_string(key)

        quote do
          def dump(unquote(key)), do: {:ok, unquote(value)}
          def dump(unquote(value)), do: {:ok, unquote(value)}
          def dump(unquote(string_key)), do: {:ok, unquote(value)}
        end
      end

    dump =
      quote do
        def dump(term) do
          msg =
            "Value `#{inspect(term)}` is not a valid enum for `#{inspect(__MODULE__)}`. " <>
              "Valid enums are `#{inspect(__valid_values__())}`"

          raise Ecto.ChangeError, message: msg
        end
      end

    dumps ++ [dump]
  end

  defp loads(kw) do
    for {key, value} <- kw do
      quote do
        def load(unquote(value)), do: {:ok, unquote(key)}
      end
    end
  end
end
