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
    assert user.enum_status == :registered
    assert User.registered?(user)
    refute User.active?(user)
    refute User.inactive?(user)
    refute User.archived?(user)

    user = TestRepo.insert!(%User{enum_status: :inactive})
    assert user.status == 2
    assert user.enum_status == :inactive
    assert User.inactive?(user)
  end

  test "sets enum on update" do
    user = TestRepo.insert!(%User{status: 0})
    user = TestRepo.update!(%{user|status: 3})
    assert user.enum_status == :archived
    assert User.archived?(user)
  end

  test "sets enum on load" do
    user = TestRepo.insert!(%User{enum_status: :active})
    user = TestRepo.get(User, user.id)
    assert user.status == 1
    assert user.enum_status == :active
    assert User.active?(user)
  end

  test "reflection functions" do
    assert User.__enums__(:status) == [registered: 0, active: 1, inactive: 2, archived: 3]
    assert User.__enums__(:enum_status) == [registered: 0, active: 1, inactive: 2, archived: 3]
  end
end

# TODO: test for ensuring that integer passed to field is within the provided options
# TODO: verify that list passed is of the expected format
