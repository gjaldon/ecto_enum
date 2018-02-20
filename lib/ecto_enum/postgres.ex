defmodule EctoEnum.Postgres do
  @moduledoc false

  def defenum(module, type, list, options \\ []) do
    quote do
      list = unquote(list) |> Macro.escape
      list = if Enum.all?(list, &is_atom/1) do
        list
      else
        Enum.map(list, &String.to_atom/1)
      end

      defmodule unquote(module) do
        @behaviour Ecto.Type
        alias EctoEnum.Postgres

        @atom_list list
        @atom_string_map for atom <- list, into: %{}, do: {atom, Atom.to_string(atom)}
        @string_atom_map for atom <- list, into: %{}, do: {Atom.to_string(atom), atom}
        @valid_values list ++ Map.values(@atom_string_map)

        # Schema-related module attributes
        @default_schema "public"
        @schema Keyword.get(unquote(options), :schema, @default_schema)
        @__type__ :"#{@schema}.#{unquote(type)}"

        def type, do: @__type__

        def schema, do: @schema

        def cast(term) do
          Postgres.cast(term, @valid_values, @string_atom_map)
        end

        def load(value) when is_binary(value) do
          Map.fetch(@string_atom_map, value)
        end

        def dump(term) do
          Postgres.dump(term, @valid_values, @atom_string_map)
        end

        def valid_value?(value) do
          Enum.member?(@valid_values, value)
        end

        # Reflection
        def __enum_map__(), do: @atom_list
        def __valid_values__(), do: @valid_values

        @types Enum.map_join(unquote(list), ", ", &"'#{&1}'")
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
  end

  def cast(atom, valid_values, _) when is_atom(atom) do
    if atom in valid_values do
      {:ok, atom}
    else
      :error
    end
  end

  def cast(string, _, string_atom_map) when is_binary(string) do
    Map.fetch(string_atom_map, string)
  end

  def cast(_, _, _), do: :error

  def dump(atom, _, atom_string_map) when is_atom(atom) do
    Map.fetch(atom_string_map, atom)
  end

  def dump(string, valid_values, _) when is_binary(string) do
    if string in valid_values do
      {:ok, string}
    else
      :error
    end
  end

  def dump(_, _, _), do: :error
end
