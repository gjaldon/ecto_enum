defmodule Ecto.Enum do

  defmacro __using__(_) do
    quote do
      @before_compile Ecto.Enum
    end
  end

  defmacro __before_compile__(env) do
    mod    = env.module
    fields = Module.get_attribute(mod, :changeset_fields)
    enums  = Module.get_attribute(mod, :enums)

    if enums do
      for {name, enum_list} <- enums do
        if fields[name] != :integer do
          raise ArgumentError, "only an `:integer` field can be an enum"
        end

        enum_map =
          for {field, number} <- enum_list, into: %{} do
            {number, field}
          end

        helper_fields =
          for {field, number} <- enum_list do
            quote do
              Ecto.Schema.__field__(unquote(mod), unquote(field), :boolean,
                                    false, virtual: true)
            end
          end

        quote do
          name = unquote(name)
          enum_field = :"enum_#{name}"
          enum_list = unquote(enum_list)
          enum_map  = unquote(enum_map)

          unquote(helper_fields)
          Ecto.Schema.__field__(unquote(mod), enum_field, :string, false, virtual: true)
          before_insert Ecto.Enum, :before_insert, name, enum_field, enum_list
          after_load    Ecto.Enum, :set_enum, name, enum_field, enum_map, enum_list
        end
      end
    end
  end

  import Ecto.changeset

  def set_enum(model, name, enum_field, enum_map, enum_list) do
    int = model[name]
    current_value = enum_map[int]
    model
    |> Map.put(enum_field, current_value)
    |> Map.put(current_value, true)
  end

  def before_insert(changeset, name, enum_field, enum_list) do
    cond do
      get_change(changeset, name) ->
        changeset

      get_change(changeset, enum_field) ->
        enum_int = enum_list[enum_field]
        change(changeset, [{name, enum_int}])

      true ->
        changeset
    end
  end
end


# @enums status: [draft: 0, published: 1]

# post.enum_status #=> "draft"
# post.draft? #=> true
# post.published? #=> false
# post.status #=> 0
# Repo.insert(%{post|enum_status: "published"})
