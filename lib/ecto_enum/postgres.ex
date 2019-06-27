defmodule EctoEnum.Postgres do
  @moduledoc """
  This module can be `use`d to create an Ecto Enum.

  Usage:

      defmodule NewType do
        use EctoEnum.Postgres, type: :new_type, enums: [:ready, :set, :go], schema: "this_is_optional"
      end

  Note that `:type` and `:enums` are required, while `:schema` is optional.

  This module is meant to be used when you want to use User-defined Types in PostgreSQL.
  """

  defmacro __using__(opts) do
    quote do
      use EctoEnum.Postgres.Use, unquote(opts)
    end
  end

  def defenum(module, type, list, options \\ []) do
    quote do
      list = unquote(list) |> Macro.escape()

      list =
        if Enum.all?(list, &is_atom/1) do
          list
        else
          Enum.map(list, &String.to_atom/1)
        end

      opts = Keyword.merge([enums: list, type: unquote(type)], unquote(options))

      defmodule unquote(module) do
        use EctoEnum.Postgres.Use, opts
      end
    end
  end
end
