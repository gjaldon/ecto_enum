defmodule EctoEnum.Typespec.TestModule do
  @moduledoc """
  Sample enum-containing module for testing type generation. Types aren't
  generated for dynamically generated modules that eunit uses, so we have to
  prepare this module in advance
  """

  import EctoEnum

  defenum StatusEnum, registered: 0, active: 1, inactive: 2, archived: 3

  defenum PGStatusEnum, :status, [:registered, :active, :inactive, :archived]
end
