defmodule EctoEnum.Typespec do
  @moduledoc "Helper for generating enum typespecs"

  def make(enums) do
    enums
    |> Enum.reverse()
    |> Enum.reduce(fn
      a, acc when is_atom(a) or is_binary(a) -> add_type(a, acc)
      {a, _}, acc when is_atom(a) -> add_type(a, acc)
      _, acc -> acc
    end)
  end

  defp add_type(type, acc), do: {:|, [], [type, acc]}
end
