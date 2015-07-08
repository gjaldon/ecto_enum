defmodule Ecto.Enum do
  @moduledoc """
  Sets enum field and provides enum helper functions.

  `Ecto.Enum` provides an `enum` macro that is used inside an Ecto model's
  `schema` block. For example:

      enum :status, [registered: 0, active: 1, inactive: 2, archived: 3]

  ### Enum fields

  `:status` in the above example is an `:integer` field in the model's table.
  The above declaration will set a `:status` integer field and an `:enum_status`
  virtual field. Calling `model.status` will return the integer value `1`, `2`
  or `3`. Invoking `model.enum_status` will return either `:registered`, `:active`,
  `:inactive` and :`archived`.

  ### Helper functions

  Apart from setting those fields, helper functions will also be defined. For
  the above example, the followings functions will be available:

      Model.registered?(model)
      Model.active?(model)
      Model.inactive?(model)
      Model.archived?(model)

  ### Reflection function

  Inspecting `enums` in an Ecto model during runtime is possible through the
  provision of an `__enums__/1` function. With this invoked, you will get the
  keyword list that represents enum mappings for a given field. For example:

      iex> Model.__enums__(:status)
      [registered: 0, active: 1, inactive: 2, archived: 3]
      iex> Model.__enums__(:enum_status)
      [registered: 0, active: 1, inactive: 2, archived: 3]

  As you notice, it works for both the integer enum field and the virtual
  enum field.
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

        defmacro __using__(_) do
          enum_kw = unquote(enum_kw)
          quote do
            def __enums__(:status), do: unquote(enum_kw)
          end
        end

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
