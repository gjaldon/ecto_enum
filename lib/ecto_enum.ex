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

  Passing a value that the custom Enum type does not recognize will result in an error.

      iex> Repo.insert!(%User{status: :none})
      ** (Elixir.EctoEnum.Error) :none is not a valid enum value

  The enum type `StatusEnum` will also have a reflection function for inspecting the
  enum map in runtime.

      iex> StatusEnum.__enum_map__()
      [registered: 0, active: 1, inactive: 2, archived: 3]
  """

  defmodule Error do
    defexception [:message]

    def exception(value) do
      msg = "#{inspect value} is not a valid enum value"
      %__MODULE__{message: msg}
    end
  end

  defmacro defenum(module, enum) when is_list(enum) do
    quote do
      kw = unquote(enum) |> Macro.escape

      defmodule unquote(module) do
        @behaviour Ecto.Type

        @atom_int_kw kw
        @int_atom_map for {atom, int} <- kw, into: %{}, do: {int, atom}
        @string_int_map for {atom, int} <- kw, into: %{}, do: {Atom.to_string(atom), int}

        def type, do: :integer

        def cast(term) do
          check_value!(term)
          EctoEnum.cast(term, @int_atom_map)
        end

        def load(int) when is_integer(int) do
          {:ok, @int_atom_map[int]}
        end

        def dump(term) do
          check_value!(term)
          EctoEnum.dump(term, @atom_int_kw, @string_int_map)
        end

        # Reflection
        def __enum_map__(), do: @atom_int_kw


        defp check_value!(atom) when is_atom(atom) do
          unless @atom_int_kw[atom] do
            raise EctoEnum.Error, atom
          end
        end

        defp check_value!(string) when is_binary(string) do
          unless @string_int_map[string] do
            raise EctoEnum.Error, string
          end
        end

        defp check_value!(int) when is_integer(int) do
          unless @int_atom_map[int] do
            raise EctoEnum.Error, int
          end
        end
      end
    end
  end

  def cast(atom, _enum_map) when is_atom(atom), do: {:ok, atom}

  def cast(string, _enum_map) when is_binary(string), do: {:ok, String.to_atom(string)}

  def cast(int, enum_map) when is_integer(int) do
    atom = enum_map[int]
    {:ok, atom}
  end

  def cast(_term), do: :error

  def dump(integer, _int_atom_map, _string_int_map) when is_integer(integer) do
    {:ok, integer}
  end

  def dump(atom, atom_int_kw, _string_int_map) when is_atom(atom) do
    integer = atom_int_kw[atom]
    {:ok, integer}
  end

  def dump(string, _int_atom_map, string_int_map) when is_binary(string) do
    integer = string_int_map[string]
    {:ok, integer}
  end

  def dump(_), do: :error
end
