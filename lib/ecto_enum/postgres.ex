defmodule EctoEnum.Postgres do
  @moduledoc false

  def defenum(module, type, list, options) do
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
        @default_schema "public"

        def type, do: :"#{schema()}.#{unquote(type)}"

        def schema do
          Keyword.get(unquote(options), :schema, @default_schema)
        end


        def cast(term) do
          Postgres.cast(term, @valid_values, @string_atom_map)
        end

        def load(value) when is_binary(value) do
          Map.fetch(@string_atom_map, value)
        end

        def dump(term) do
          Postgres.dump(term, @valid_values, @atom_string_map)
        end

        # Reflection
        def __enum_map__(), do: @atom_list
        def __valid_values__(), do: @valid_values

        def create_type() do
          types = Enum.map_join(unquote(list), ", ", &"'#{&1}'")
          sql = "CREATE TYPE #{type()} AS ENUM (#{types})"
          Ecto.Migration.execute sql
        end

        def drop_type() do
          sql = "DROP TYPE #{type()}"
          Ecto.Migration.execute sql
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
