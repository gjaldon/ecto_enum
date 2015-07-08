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

  import Ecto.Changeset

  defmacro defenum(module, enum_kw) do
    enum_map = for {atom, int} <- enum_kw, into: %{}, do: {int, atom}
    enum_kw_string = for {atom, int} <- enum_kw, do: {Atom.to_string(atom), int}

    quote do
      defmodule unquote(module) do
        @behaviour Ecto.Type

        def type, do: :integer

        def cast(atom) when is_atom(atom), do: {:ok, atom}
        def cast(string) when is_binary(string) do
          atom = string |> String.downcase() |> String.to_atom()
          {:ok, atom}
        end
        def cast(int) when is_integer(int) do
          atom = unquote(Macro.escape(enum_map))[int]
          {:ok, atom}
        end
        def cast(_term), do: :error

        def load(int) when is_integer(int) do
          {:ok, unquote(Macro.escape(enum_map))[int]}
        end

        def dump(int) when is_integer(int), do: {:ok, int}
        def dump(atom) when is_atom(atom), do: {:ok, unquote(enum_kw)[atom]}
        def dump(string) when is_binary(string) do
          atom = string |> String.downcase() |> String.to_atom()
          {:ok, unquote(enum_kw)[atom]}
        end
        def dump(_), do: :error
      end
    end
  end

  @doc false
  defmacro __using__(_) do
    quote do
      Module.register_attribute(__MODULE__, :ecto_enums, accumulate: true)
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    mod   = env.module
    enums = Module.get_attribute(mod, :ecto_enums)

    if enums do
      for {name, enum_list} <- enums do
        enum_map =
          for {field, number} <- enum_list, into: %{} do
            {number, field}
          end

        quote do
          name       = unquote(name)
          enum_field = :"enum_#{name}"
          enum_list  = unquote(enum_list)
          enum_map   = unquote(Macro.escape(enum_map))
          mod        = unquote(mod)

          before_insert Ecto.Enum, :set_enum, [name, enum_field, enum_map, enum_list]
          before_update Ecto.Enum, :set_enum, [name, enum_field, enum_map, enum_list]
          after_load    Ecto.Enum, :on_load, [name, enum_field, enum_map]
        end
      end
    end
  end

  @doc """
  Generates enum fields and helper functions.

  This macro is used in a the `Ecto` model's schema block. The field
  it expects must be an integer. The keyword list passed to it represents
  the enum mapping. Refer to the moduledoc for more details.
  """
  defmacro enum(field, list) when is_list(list) do
    enum_field = :"enum_#{field}"

    helper_fields =
      for {field, _number} <- list do
        helper_name = :"#{field}?"

        quote do
          def unquote(helper_name)(model) do
            value = Map.get(model, unquote(enum_field))
            unquote(field) == value
          end
        end
      end

    quote do
      field      = unquote(field)
      enum_field = unquote(enum_field)
      list       = unquote(list)

      @ecto_enums {field, list}
      Ecto.Schema.__field__(__MODULE__, field, :integer, false, [])
      Ecto.Schema.__field__(__MODULE__, enum_field, :string, false, virtual: true)
      unquote(helper_fields)
      Module.eval_quoted __ENV__, [Ecto.Enum.__enums__(field, enum_field, list)]
    end
  end

  @doc false
  def on_load(model, name, enum_field, enum_map) do
    int           = Map.get(model, name)
    current_value = enum_map[int]
    Map.put(model, enum_field, current_value)
  end

  @doc false
  def set_enum(changeset, name, enum_field, enum_map, enum_list) do
    cond do
      int = get_change(changeset, name) ->
        value = enum_map[int]
        changeset
        |> put_change(enum_field, value)

      enum_field = get_field(changeset, enum_field) ->
        enum_int = enum_list[enum_field]
        changeset
        |> change([{name, enum_int}])

      true ->
        changeset
    end
  end

  @doc false
  def __enums__(name, enum_field, enum_list) do
    quote do
      def __enums__(unquote(name)) do
        unquote(enum_list)
      end

      def __enums__(unquote(enum_field)) do
        unquote(enum_list)
      end
    end
  end
end
