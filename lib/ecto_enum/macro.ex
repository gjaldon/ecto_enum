defmodule EctoEnum.Macro do
  def to_function(s) when is_atom(s) do
    s |> to_string |> to_function()
  end

  def to_function(s) when is_binary(s) do
    s
    |> String.replace(~r/[[:punct:]]/, "_")
    |> Macro.underscore()
    |> String.to_atom()
  end
end
