defmodule EctoEnum.Postgres.Use do
  @moduledoc false

  alias EctoEnum.Typespec

  defmacro __using__(input) do
    quote bind_quoted: [input: input] do
      typespec = Typespec.make(input[:enums])

      @behaviour Ecto.Type

      if typespec do
        @type t :: unquote(typespec)
      end

      enums = input[:enums]
      valid_values = enums ++ Enum.map(enums, &Atom.to_string/1)

      for atom <- enums do
        string = Atom.to_string(atom)

        def cast(unquote(atom)), do: {:ok, unquote(atom)}
        def cast(unquote(string)), do: {:ok, unquote(atom)}
      end

      def cast(_other), do: :error

      for atom <- enums do
        string = Atom.to_string(atom)

        def dump(unquote(atom)), do: {:ok, unquote(string)}
        def dump(unquote(string)), do: {:ok, unquote(string)}
      end

      def dump(term) do
        msg =
          "Value `#{inspect(term)}` is not a valid enum for `#{inspect(__MODULE__)}`. " <>
            "Valid enums are `#{inspect(__valid_values__())}`"

        raise Ecto.ChangeError, message: msg
      end

      def embed_as(_), do: :self

      def equal?(term1, term2), do: term1 == term2

      for atom <- enums do
        string = Atom.to_string(atom)

        def load(unquote(atom)), do: {:ok, unquote(atom)}
        def load(unquote(string)), do: {:ok, unquote(atom)}
      end

      def load(_), do: :error

      def valid_value?(value) do
        Enum.member?(unquote(valid_values), value)
      end

      # # Reflection
      def __enums__(), do: unquote(enums)
      def __enum_map__(), do: __enums__()
      def __valid_values__(), do: unquote(valid_values)

      default_schema = "public"
      schema = Keyword.get(input, :schema, default_schema)
      type = :"#{schema}.#{input[:type]}"

      def type, do: unquote(type)
      def schemaless_type, do: unquote(input[:type])

      def schema, do: unquote(schema)

      types = Enum.map_join(enums, ", ", &"'#{&1}'")
      add_values_command = Enum.map_join(enums, "\n", &"ADD VALUE IF NOT EXISTS '#{&1}'")
      alter_add_values_sql = "ALTER TYPE #{type} #{add_values_command}"
      create_sql = "CREATE TYPE #{type} AS ENUM (#{types})"
      drop_sql = "DROP TYPE #{type}"

      Code.ensure_loaded(Ecto.Migration)

      if function_exported?(Ecto.Migration, :execute, 2) do
        def create_type() do
          Ecto.Migration.execute(unquote(create_sql), unquote(drop_sql))
        end

        def add_values() do
          Ecto.Migration.execute(unquote(alter_add_values_sql))
        end
      else
        def create_type() do
          Ecto.Migration.execute(unquote(create_sql))
        end

        def add_values() do
          Ecto.Migration.execute(unquote(alter_add_values_sql))
        end
      end

      def drop_type() do
        Ecto.Migration.execute(unquote(drop_sql))
      end
    end
  end
end
