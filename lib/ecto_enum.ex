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

  defmacro defenum(module, enum_kw) when is_list(enum_kw) do
    enum_map = for {atom, int} <- enum_kw, into: %{}, do: {int, atom}
    enum_map = Macro.escape(enum_map)
    enum_map_string = for {atom, int} <- enum_kw, into: %{}, do: {Atom.to_string(atom), int}
    enum_map_string = Macro.escape(enum_map_string)

    quote do
      defmodule unquote(module) do
        @behaviour Ecto.Type

        def type, do: :integer

        def cast(term) do
          check_value!(term)
          EctoEnum.cast(term, unquote(enum_map))
        end

        def load(int) when is_integer(int) do
          {:ok, unquote(enum_map)[int]}
        end

        def dump(term) do
          check_value!(term)
          EctoEnum.dump(term, unquote(enum_kw), unquote(enum_map_string))
        end

        # Reflection
        def __enum_map__(), do: unquote(enum_kw)


        defp check_value!(atom) when is_atom(atom) do
          unless unquote(enum_kw)[atom] do
            raise EctoEnum.Error, atom
          end
        end

        defp check_value!(string) when is_binary(string) do
          unless unquote(enum_map_string)[string] do
            raise EctoEnum.Error, string
          end
        end

        defp check_value!(int) when is_integer(int) do
          unless unquote(enum_map)[int] do
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

  def dump(int, _enum_kw, _enum_map_string) when is_integer(int) do
    {:ok, int}
  end

  def dump(atom, enum_kw, _enum_map_string) when is_atom(atom) do
    {:ok, enum_kw[atom]}
  end

  def dump(string, _enum_kw, enum_map_string) when is_binary(string) do
    {:ok, enum_map_string[string]}
  end

  def dump(_), do: :error
end
