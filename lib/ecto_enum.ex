defmodule EctoEnum do
  @moduledoc """
  Provides `defenum/2` macro for defining an Enum Ecto type.
  """

  @doc """
  Defines an enum custom `Ecto.Type`.

  It can be used like any other `Ecto.Type` by passing it to a field in your model's
  schema block. For example:

      import EctoEnum
      defenum StatusEnum, registered: 0, active: 1, inactive: 2, archived: 3

      defmodule User do
        use Ecto.Model

        schema "users" do
          field :status, StatusEnum
        end
      end

  In the above example, the `:status` will behave like an enum and will allow you to
  pass an `integer`, `atom` or `string` to it. This applies to saving the model,
  invoking `Ecto.Changeset.cast/4`, or performing a query on the status field. Let's
  do a few examples:

      iex> user = Repo.insert!(%User{status: 0})
      iex> Repo.get(User, user.id).status
      :registered

      iex> %{changes: changes} = cast(%User{}, %{"status" => "Active"}, ~w(status), [])
      iex> changes.status
      :active

      iex> from(u in User, where: u.status == :registered) |> Repo.all() |> length
      1

  Passing an invalid value to a `Ecto.Changeset.cast/3` will add an error to `changeset.errors`
  field.

      iex> changeset = cast(%User{}, %{"status" => "retroactive"}, ~w(status), [])
      iex> changeset.errors
      [status: "is invalid"]

  Passing an invalid value directly into a model struct will in an error when calling
  `Repo` functions.

      iex> Repo.insert!(%User{status: :none})
      ** (Ecto.ChangeError) `"none"` is not a valid enum value for `EctoEnumTest.StatusEnum`.
      Valid enum values are `[0, 1, 2, 3, :registered, :active, :inactive, :archived, "active",
      "archived", "inactive", "registered"]`

  The enum type `StatusEnum` will also have a reflection function for inspecting the
  enum map in runtime.

      iex> StatusEnum.__enum_map__()
      [registered: 0, active: 1, inactive: 2, archived: 3]
  """

  defmacro defenum(module, type, enum) when is_list(enum) do
    EctoEnum.Postgres.defenum(module, type, enum)
  end

  defmacro defenum(module, enum) when is_list(enum) do
    quote do
      kw = unquote(enum) |> Macro.escape

      defmodule unquote(module) do
        @behaviour Ecto.Type

        @atom_int_kw kw
        @int_atom_map for {atom, int} <- kw, into: %{}, do: {int, atom}
        @string_int_map for {atom, int} <- kw, into: %{}, do: {Atom.to_string(atom), int}
        @string_atom_map for {atom, int} <- kw, into: %{}, do: {Atom.to_string(atom), atom}
        @valid_values Keyword.values(@atom_int_kw) ++ Keyword.keys(@atom_int_kw) ++ Map.keys(@string_int_map)

        def type, do: :integer

        def cast(term) do
          EctoEnum.cast(term, @int_atom_map, @string_atom_map)
        end

        def load(int) when is_integer(int) do
          Map.fetch(@int_atom_map, int)
        end
        def load(str) when is_binary(str) do
          Map.fetch(@string_atom_map, str)
        end

        def dump(term) do
          case EctoEnum.dump(term, @atom_int_kw, @string_int_map, @int_atom_map) do
            :error ->
              msg = "`#{inspect term}` is not a valid enum value for `#{inspect __MODULE__}`. " <>
                "Valid enum values are `#{inspect __valid_values__}`"
              raise Ecto.ChangeError,
                message: msg
            value ->
              value
          end
        end

        # Reflection
        def __enum_map__(), do: @atom_int_kw
        def __valid_values__(), do: @valid_values
      end
    end
  end

  @spec cast(any, map, map) :: {:ok, atom} | :error
  def cast(atom, int_atom_map, _) when is_atom(atom) do
    if atom in Map.values(int_atom_map) do
      {:ok, atom}
    else
      :error
    end
  end
  def cast(string, _, string_atom_map) when is_binary(string) do
    Map.fetch(string_atom_map, string)
  end
  def cast(int, int_atom_map, _) when is_integer(int) do
    Map.fetch(int_atom_map, int)
  end
  def cast(_, _, _), do: :error


  @spec dump(any, keyword, map, map) :: {:ok, integer} | :error
  def dump(integer, _, _, int_atom_map) when is_integer(integer) do
    if int_atom_map[integer] do
      {:ok, integer}
    else
      :error
    end
  end
  def dump(atom, atom_int_kw, _, _) when is_atom(atom) do
    Keyword.fetch(atom_int_kw, atom)
  end
  def dump(string, _, string_int_map, _) when is_binary(string) do
    Map.fetch(string_int_map, string)
  end
  def dump(_), do: :error
end
