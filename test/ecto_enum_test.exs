defmodule EctoEnumTest do
  use ExUnit.Case

  defmodule User do
    use Ecto.Schema
      import Ecto.Changeset
      import Ecto.Query, only: [from: 2]

      import Ecto.Model
      use Ecto.Model.OptimisticLock
      use Ecto.Model.Timestamps
      use Ecto.Enum
      use Ecto.Model.Callbacks

    schema "users" do
      import Ecto.Enum
      enum :status, [registered: 0, active: 1, inactive: 2, archived: 3]
    end
  end

  alias Ecto.Integration.TestRepo

  test "loading model with enum field" do
    user = TestRepo.insert!(%User{status: 0})
    assert user.status == 0
    assert user.enum_status == :registered
  end

  # test "inserting with enum field sets status" do
  #   user = TestRepo.insert!(%User{enum_status: "registered"})
  #   assert user.status == 0
  #   assert user.enum_status == "registered"
  # end

  test "reflections functions" do
    assert User.__enums__(:status) == [registered: 0, active: 1, inactive: 2, archived: 3]
    assert User.__enums__(:enum_status) == [registered: 0, active: 1, inactive: 2, archived: 3]
  end
end
