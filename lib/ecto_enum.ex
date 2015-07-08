defmodule Ecto.Enum do
  @moduledoc """
  Provides `defenum/2` macro for defining an Enum Ecto type.
  """

  @doc """
  Defines an enum custom `Ecto.Type`.

  It can be used like any other `Ecto.Type` by passing it to a field in your model's
  schema block. For example:

      import Ecto.Enum
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
      ** (Elixir.StatusEnum.Error) :none is not a valid enum value

  The enum type `StatusEnum` will also have a reflection function for inspecting the
  enum map in runtime.

      iex> StatusEnum.__enum_map__(:status)
      [registered: 0, active: 1, inactive: 2, archived: 3]
  """
  defmacro defenum(module, enum_kw) when is_list(enum_kw) do
    enum_map = for {atom, int} <- enum_kw, into: %{}, do: {int, atom}
    enum_map = Macro.escape(enum_map)
    enum_map_string = for {atom, int} <- enum_kw, into: %{}, do: {Atom.to_string(atom), int}
    enum_map_string = Macro.escape(enum_map_string)
    error_mod = Module.concat(elem(module, 2) ++ [Error])

    quote do
      defmodule unquote(error_mod) do
        defexception [:message]

        def exception(value) do
          msg = "#{inspect value} is not a valid enum value"
          %__MODULE__{message: msg}
        end
      end

      defmodule unquote(module) do
        @behaviour Ecto.Type

        def type, do: :integer

        def cast(atom) when is_atom(atom) do
          check_value!(atom)
          {:ok, atom}
        end

        def cast(string) when is_binary(string) do
          string = String.downcase(string)
          check_value!(string)
          {:ok, String.to_atom(string)}
        end

        def cast(int) when is_integer(int) do
          check_value!(int)
          atom = unquote(enum_map)[int]
          {:ok, atom}
        end

        def cast(_term), do: :error

        def load(int) when is_integer(int) do
          {:ok, unquote(enum_map)[int]}
        end

        def dump(int) when is_integer(int) do
          check_value!(int)
          {:ok, int}
        end

        def dump(atom) when is_atom(atom) do
          check_value!(atom)
          {:ok, unquote(enum_kw)[atom]}
        end

        def dump(string) when is_binary(string) do
          string = String.downcase(string)
          check_value!(string)
          {:ok, unquote(enum_map_string)[string]}
        end

        def dump(_), do: :error

        # Reflection
        def __enum_map__(:status), do: unquote(enum_kw)


        defp check_value!(atom) when is_atom(atom) do
          unless unquote(enum_kw)[atom] do
            raise unquote(error_mod), atom
          end
        end

        defp check_value!(string) when is_binary(string) do
          unless unquote(enum_map_string)[string] do
            raise unquote(error_mod), string
          end
        end

        defp check_value!(int) when is_integer(int) do
          unless unquote(enum_map)[int] do
            raise unquote(error_mod), int
          end
        end
      end
    end
  end
end
