defmodule EctoEnum do
  @moduledoc """
  Provides `defenum/2` and `defenum/3` macro for defining an Enum Ecto type.

  This module can also be `use`d to create an Ecto Enum like:

      defmodule CustomEnum do
        use EctoEnum, ready: 0, set: 1, go: 2
      end

  Or in place of using `EctoEnum.Postgres` like:

      defmodule PostgresType do
        use EctoEnum, type: :new_type, enums: [:ready, :set, :go]
      end

  The difference between the above two examples is that the previous one would use an
  integer column in the database while the latter one would use a custom type in PostgreSQL.

  Note that only PostgreSQL is supported for custom data types at the moment.
  """

  @doc """
  Defines an enum custom `Ecto.Type`.

  For second argument, it accepts either a list of strings or a keyword list with keyword
  values that are either strings or integers. Below are examples of a valid argument:
      [registered: 0, active: 1, inactive: 2, archived: 3]
      [registered: "registered", active: "active", inactive: "inactive", archived: "archived"]
      ["registered", "active", "inactive", "archived"]

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

  Enums also generate a typespec for use with dialyzer, available as the `t()` type

      iex> t(StatusEnum)
      @type t() :: :registered | :active | :inactive | :archived
  """

  defmacro __using__(opts) do
    quote do
      opts = unquote(opts)

      if opts[:type] && opts[:enums] do
        use EctoEnum.Postgres.Use, unquote(opts)
      else
        use EctoEnum.Use, unquote(opts)
      end
    end
  end

  defmacro defenum(module, type, enum, options \\ []) do
    EctoEnum.Postgres.defenum(module, type, enum, options)
  end

  defmacro defenum(module, enum) do
    quote do
      enum = Macro.escape(unquote(enum))

      enum =
        cond do
          Keyword.keyword?(enum) ->
            enum

          enum |> List.first() |> is_binary() ->
            Enum.map(enum, fn value -> {String.to_atom(value), value} end)

          true ->
            raise "Enum must be a keyword list or a list of strings"
        end

      defmodule unquote(module) do
        use EctoEnum.Use, enum
      end
    end
  end

  alias Ecto.Changeset

  @spec validate_enum(
          Ecto.Changeset.t(),
          atom,
          (atom, String.t(), list(String.t() | integer | atom) -> String.t())
        ) :: Ecto.Changeset.t()
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
    "Value `#{inspect(value)}` is not a valid enum for `#{inspect(field)}` field. " <>
      "Valid enums are `#{inspect(valid_values)}`"
  end
end
