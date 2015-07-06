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
      for {name, enum_map} <- enums do
        if fields[name] != :integer do
          raise ArgumentError, "only an `:integer` field can be an enum"
        end

        helper_fields =
          for {field, number} <- enum_map do
            quote do
              Ecto.Schema.__field__(unquote(mod), :"#{unquote(field)}?",
                                    :boolean, false, virtual: true)
            end
          end

        quote do
          unquote(helper_fields)
          Ecto.Schema.__field__(unquote(mod), :"enum_#{unquote(name)}",
                                :boolean, false, virtual: true)
          before_insert Ecto.Enum, :before_insert, unquote(name), unquote(enum_map)
        end
      end
    end
  end

  import Ecto.changeset

  def before_insert(changeset, enum_field, enum_map) do
    enum_virtual_field = :"enum_#{enum_field}"
    cond do
      get_change(changeset, enum_field) ->
        changeset

      get_change(changeset, enum_virtual_field) ->
        enum_int = enum_map[enum_virtual_field]
        change(changeset, [{enum_field, enum_int}])

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
