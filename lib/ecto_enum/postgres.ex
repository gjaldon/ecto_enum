defmodule EctoEnum.Postgres do

  def defenum(module, type, list) do
    list = if Enum.all?(list, &is_atom/1) do
        list
      else
        Enum.map(list, &String.to_atom/1)
      end

    quote do
      type = unquote(type) |> Macro.escape
      list = unquote(list) |> Macro.escape

      defmodule unquote(module) do
        @behaviour Ecto.Type
        alias EctoEnum.Postgres

        @atom_list list
        @atom_string_map for atom <- list, into: %{}, do: {atom, Atom.to_string(atom)}
        @string_atom_map for atom <- list, into: %{}, do: {Atom.to_string(atom), atom}
        @valid_values list ++ Map.values(@atom_string_map)

        def type, do: unquote(type)

        def cast(term) do
          Postgres.cast(term, @valid_values, @string_atom_map)
        end

        def load(value) do
          {:ok, @string_atom_map[value]}
        end

        def dump(term) do
          Postgres.dump(term, @valid_values, @atom_string_map)
        end

        # Reflection
        def __enum_map__(), do: @atom_list
        def __valid_values__(), do: @valid_values
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
    if atom = string_atom_map[string] do
      {:ok, atom}
    else
      :error
    end
  end
  def cast(term, _, _), do: :error


  def dump(atom, valid_values, atom_string_map) when is_atom(atom) do
    if string = atom_string_map[atom] do
      {:ok, string}
    else
      :error
    end
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
