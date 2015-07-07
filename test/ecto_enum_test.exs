defmodule EctoEnumTest do
  use ExUnit.Case

  defmodule User do
    use Ecto.Schema
      use Ecto.Enum
      use Ecto.Model

    schema "users" do
      enum :status, [registered: 0, active: 1, inactive: 2, archived: 3]
    end
  end

  alias Ecto.Integration.TestRepo

  test "sets enum on insert" do
    user = TestRepo.insert!(%User{status: 0})
    assert user.status == 0
    assert user.enum_status == :registered
    assert user.registered
    refute user.active
    refute user.inactive
    refute user.archived

    user = TestRepo.insert!(%User{enum_status: :inactive})
    assert user.status == 2
    assert user.enum_status == :inactive
    assert user.inactive
  end

  test "sets enum on load" do
    user = TestRepo.insert!(%User{enum_status: :active})
    user = TestRepo.get(User, user.id)
    assert user.status == 1
    assert user.enum_status == :active
    assert user.active
  end

  test "reflections functions" do
    assert User.__enums__(:status) == [registered: 0, active: 1, inactive: 2, archived: 3]
    assert User.__enums__(:enum_status) == [registered: 0, active: 1, inactive: 2, archived: 3]
  end
end
