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
        use Ecto.Schema

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

  You may also use strings as backing storage rather than integers by specifying string
  values in place of integral ones.

      defenum RoleEnum, user: "string_for_user", admin: "string_for_admin"

  They expose all of the same functionality as integer backed storage.
  """

  defmodule UndeterminableStorageError do
    defexception [:message]

    def exception(kw) do
      msg = "You have conflicting data types! EctoEnum can only store using " <>
            "one type (integers or strings but not both) for the same enum. " <>
            "Original keyword was #{inspect kw}"
      %__MODULE__{message: msg}
    end
  end

  defmacro defenum(module, type, enum) do
    EctoEnum.Postgres.defenum(module, type, enum)
  end

  defmacro defenum(module, enum) do
    quote do
      kw = unquote(enum) |> Macro.escape

      storage = EctoEnum.storage(kw)

      if storage == :indeterminate, do: raise(EctoEnum.UndeterminableStorageError, kw)

      defmodule unquote(module) do
        @behaviour Ecto.Type

        @atom_rawval_kw kw
        @rawval_atom_map for {atom, rawval} <- kw, into: %{}, do: {rawval, atom}
        @string_rawval_map for {atom, rawval} <- kw, into: %{}, do: {Atom.to_string(atom), rawval}
        @string_atom_map for {atom, _} <- kw, into: %{}, do: {Atom.to_string(atom), atom}
        @valid_values Keyword.values(@atom_rawval_kw) ++ Keyword.keys(@atom_rawval_kw) ++ Map.keys(@string_rawval_map)

        @storage storage

        def type, do: @storage

        def cast(term) do
          EctoEnum.Type.cast(term, @rawval_atom_map, @string_atom_map)
        end

        def load(rawval) do
          Map.fetch(@rawval_atom_map, rawval)
        end

        def dump(term) do
          case EctoEnum.Type.dump(term, @atom_rawval_kw, @string_rawval_map, @rawval_atom_map) do
            :error ->
              msg = "Value `#{inspect term}` is not a valid enum for `#{inspect __MODULE__}`. " <>
                "Valid enums are `#{inspect __valid_values__()}`"
              raise Ecto.ChangeError,
                message: msg
            value ->
              value
          end
        end

        def valid_value?(value) do
          Enum.member?(@valid_values, value)
        end

        # Reflection
        def __enum_map__(), do: @atom_rawval_kw
        def __valid_values__(), do: @valid_values
      end
    end
  end

  def storage(kw) do
    cond do
      Enum.all?(kw, &(is_integer(elem(&1, 1)))) -> :integer
      Enum.all?(kw, &(is_binary(elem(&1, 1)))) -> :string
      true -> :indeterminate
    end
  end

  defmodule Type do
    @spec cast(any, map, map) :: {:ok, atom} | :error
    def cast(atom, rawval_atom_map, _) when is_atom(atom) do
      if atom in Map.values(rawval_atom_map) do
        {:ok, atom}
      else
        :error
      end
    end
    def cast(val, rawval_atom_map, string_atom_map) do
      if val in Map.keys(rawval_atom_map) do
        Map.fetch(rawval_atom_map, val)
      else
        Map.fetch(string_atom_map, val)
      end
    end

    @spec dump(any, [{atom(), any()}], map, map) :: {:ok, integer | string} | :error
    def dump(atom, atom_rawval_kw, _, _) when is_atom(atom) do
      Keyword.fetch(atom_rawval_kw, atom)
    end
    def dump(val, _, string_rawval_map, rawval_atom_map) do
      if val in Map.keys(rawval_atom_map) do
        {:ok, val}
      else
        Map.fetch(string_rawval_map, val)
      end
    end
  end

  alias Ecto.Changeset
  @spec validate_enum(Ecto.Changeset.t, atom, ((atom, String.t, list(String.t | integer | atom)) -> String.t)) :: Ecto.Changeset.t
  def validate_enum(changeset, field, error_msg \\ &default_error_msg/3) do
    Changeset.validate_change(changeset, field, :validate_enum, fn field, value ->
      type = changeset.types[field]
      error_msg = error_msg.(field, value, type.__valid_values__())
      if type.valid_value?(value) do
        []
      else
        Keyword.put([], field, error_msg)
      end
    end)
  end

  defp default_error_msg(field, value, valid_values) do
    "Value `#{inspect value}` is not a valid enum for `#{inspect field}` field. " <>
      "Valid enums are `#{inspect valid_values}`"
  end
end
