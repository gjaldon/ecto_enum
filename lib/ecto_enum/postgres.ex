defmodule EctoEnum.Postgres do
  @moduledoc false

  def defenum(module, type, list, options \\ []) do
    quote do
      list = unquote(list) |> Macro.escape()

      list =
        if Enum.all?(list, &is_atom/1) do
          list
        else
          Enum.map(list, &String.to_atom/1)
        end

      opts = [enums: list, type: unquote(type), opts: unquote(options)]

      defmodule unquote(module) do
        use EctoEnum.Postgres.Use, opts
      end
    end
  end
end
