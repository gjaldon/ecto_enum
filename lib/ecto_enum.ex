defmodule EctoEnum do
  @moduledoc """
  Provides `enum/1` macro to define the list of valid values.
  """

  @doc """
  Provides `enum/1` macro to define the list of valid values.

  It can be used like any other `Ecto.Type` by passing it to a field in your model's
  schema block. For example:

      defmodule StatusEnum do
        use EctoEnum
        enum ~w(registered active inactive archived)
      end

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

      iex> %{changes: changes} = cast(%User{}, %{"status" => "active"}, ~w(status), [])
      iex> changes.status
      :active

      iex> from(u in User, where: u.status == :registered) |> Repo.all() |> length
      1

  Passing a value that the custom Enum type does not recognize will result in an error.

      iex> %{errors: errors} = cast(%User{}, %{"status" => :retroactive}, ~w(status), [])
      iex> errors
      [status: "is invalid"]

      iex> Repo.insert!(%User{status: :none})
      ** (Elixir.EctoEnum.Error) :none is not a valid enum value

  The enum type `StatusEnum` will also have a reflection function for inspecting the
  enum map in runtime.

      iex> StatusEnum.__enum_map__()
      ["registered", "active", "inactive", "archived"]

      iex> StatusEnum.__meta__()
      %{0 => "registered", 1 => "active", 2 => "inactive", 3 => "archived",
        "active" => 1, "archived" => 3, "inactive" => 2, "registered" => 0}
  """

  defmodule Error do
    defexception [:message]

    def exception(value) do
      msg = "#{inspect value} is not a valid enum value"
      %__MODULE__{message: msg}
    end
  end


  defmacro __using__(_opts) do
    quote do
      @behaviour Ecto.Type

      import EctoEnum

      def type, do: :integer

      def cast(term) do
        EctoEnum.cast(term, __meta__)
      end

      def load(term) do
        EctoEnum.load(term, __meta__)
      end

      def dump(term) do
        EctoEnum.dump(term, __meta__)
      end
    end
  end

  defmacro enum(enums, _opts \\ []) do
    quote do
      def __meta__, do: EctoEnum.enums_to_map(unquote(enums))
      def __enum_map__, do: unquote(enums)
    end
  end

  # compatilibidade with the previous version
  defmacro defenum(module, enum_kw) when is_list(enum_kw) do
    quote do
      kw = unquote(enum_kw) |> Macro.escape

      defmodule unquote(module) do
        use EctoEnum

        @enum_kw kw
        enum @enum_kw
      end
    end
  end


  def cast(term, enum_map) do
    case to_atom(term, enum_map) do
      :error -> :error
      value  -> {:ok, value}
    end
  end

  def load(term, enum_map) do
    case to_atom(term, enum_map) do
      :error -> :error
      value  -> {:ok, value}
    end
  end

  def dump(term, enum_map) do
    case to_integer(term, enum_map) do
      :error -> raise_error term
      value  -> {:ok, value}
    end
  end

  def dump(_), do: :error

  @doc """
  Fetch value (integer) from string or atom
  Fetch values (list of integer) from list of strings or atoms
  """
  def to_integer(term, enum_map) when is_atom(term), do: to_integer(to_string(term), enum_map)

  def to_integer(term, enum_map) when is_bitstring(term) do
    Map.get(enum_map, term, :error)
  end

  def to_integer(term, enum_map) when is_integer(term) do
    case Map.get(enum_map, term, :error) do
      :error -> :error
      _ -> term
    end
  end

  @doc """
  Fetch name (string or atom) from integer
  Fetch names (list of strings or atoms) from list of integers
  """
  def to_atom(term, enum_map) when is_integer(term) do
    case Map.get(enum_map, term, :error) do
      :error -> :error
      string -> String.to_atom(string)
    end
  end

  def to_atom(value, enum_map) when is_atom(value), do: to_atom(to_string(value), enum_map)

  def to_atom(value, enum_map) when is_bitstring(value) do
    case Map.has_key?(enum_map, value) do
      true -> String.to_atom(value)
      _ -> :error
    end
  end

  def enums_to_map([{_, _} | _] = keyword) do
    keyword
    |> Enum.reduce(%{}, fn({term, ix}, acc) ->
      unless is_integer(ix) do
        raise ArgumentError, "#{inspect ix} is not an integer index integer. (#{inspect keyword})"
      end
      map = Enum.into([
        {to_string(term), ix},
        {ix, to_string(term)}
      ], %{})

      acc |> Map.merge(map)
    end)
  end

  def enums_to_map(list) do
    list
    |> Enum.with_index
    |> enums_to_map
  end

  def raise_error(term) do
    raise EctoEnum.Error, term
  end

end
