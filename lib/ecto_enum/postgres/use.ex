defmodule EctoEnum.Postgres.Use do
  @moduledoc false

  defmacro __using__(input) do
    quote do
      @behaviour Ecto.Type

      input = unquote(input)

      enums = input[:enums]

      Module.put_attribute(__MODULE__, :enums, enums)

      @before_compile EctoEnum.Postgres.Use

      @valid_values enums ++ Enum.map(enums, &Atom.to_string/1)

      # Schema-related module attributes
      @default_schema "public"
      @schema Keyword.get(input, :schema, @default_schema)
      @__type__ :"#{@schema}.#{input[:type]}"

      def type, do: @__type__

      def schema, do: @schema

      def valid_value?(value) do
        Enum.member?(@valid_values, value)
      end

      # # Reflection
      def __enums__(), do: @enums
      def __enum_map__(), do: __enums__()
      def __valid_values__(), do: @valid_values

      @types Enum.map_join(enums, ", ", &"'#{&1}'")
      @create_sql "CREATE TYPE #{@__type__} AS ENUM (#{@types})"
      @drop_sql "DROP TYPE #{@__type__}"

      if function_exported?(Ecto.Migration, :execute, 2) do
        def create_type() do
          Ecto.Migration.execute(@create_sql, @drop_sql)
        end
      else
        def create_type() do
          Ecto.Migration.execute(@create_sql)
        end
      end

      def drop_type() do
        Ecto.Migration.execute(@drop_sql)
      end
    end
  end

  defmacro __before_compile__(env) do
    enums = Module.get_attribute(env.module, :enums)

    casts(enums) ++ dumps(enums) ++ loads(enums)
  end

  defp casts(enums) do
    casts =
      for atom <- enums do
        string = Atom.to_string(atom)

        quote do
          def cast(unquote(atom)), do: {:ok, unquote(atom)}
          def cast(unquote(string)), do: {:ok, unquote(atom)}
        end
      end

    cast =
      quote do
        def cast(_other), do: :error
      end

    casts ++ [cast]
  end

  defp dumps(enums) do
    dumps =
      for atom <- enums do
        string = Atom.to_string(atom)

        quote do
          def dump(unquote(atom)), do: {:ok, unquote(string)}
          def dump(unquote(string)), do: {:ok, unquote(string)}
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

  defp loads(enums) do
    for atom <- enums do
      string = Atom.to_string(atom)

      quote do
        def load(unquote(atom)), do: {:ok, unquote(atom)}
        def load(unquote(string)), do: {:ok, unquote(atom)}
      end
    end
  end
end
