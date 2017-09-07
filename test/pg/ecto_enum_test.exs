defmodule EctoEnumTest do
  use ExUnit.Case

  import EctoEnum

  defenum RoleEnum, user: "string_for_user", admin: "string_for_admin"
  defenum StatusEnum, [registered: 0, active: 1, inactive: 2, archived: 3]

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field :role, RoleEnum
      field :status, StatusEnum
    end
  end

  alias Ecto.Integration.TestRepo

  test "accepts int, atom and string on save" do
    user = TestRepo.insert!(%User{status: 0})
    user = TestRepo.get(User, user.id)
    assert user.status == :registered

    user = Ecto.Changeset.change(user, status: :active)
    user = TestRepo.update! user
    assert user.status == :active

    user = Ecto.Changeset.change(user, status: "inactive")
    user = TestRepo.update! user
    assert user.status == "inactive"

    user = TestRepo.get(User, user.id)
    assert user.status == :inactive

    TestRepo.insert!(%User{status: :archived})
    user = TestRepo.get_by(User, status: :archived)
    assert user.status == :archived

    TestRepo.insert!(%User{role: :user})
    user = TestRepo.get_by(User, role: :user)
    assert user.role == :user

    TestRepo.insert!(%User{role: "string_for_admin"})
    user = TestRepo.get_by(User, role: "string_for_admin")
    assert user.role == :admin
  end

  test "casts int and binary to atom" do
    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"status" => "active"}, ~w(status))
    assert changes.status == :active

    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"status" => 3}, ~w(status))
    assert changes.status == :archived

    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"status" => :inactive}, ~w(status))
    assert changes.status == :inactive

    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"role" => "user"}, ~w(role))
    assert changes.role == :user

    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"role" => "string_for_user"}, ~w(role))
    assert changes.role == :user

    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"role" => :user}, ~w(role))
    assert changes.role == :user
  end

  test "raises when input is not in the enum map" do
    error = {:status, {"is invalid", [type: EctoEnumTest.StatusEnum, validation: :cast]}}

    changeset = Ecto.Changeset.cast(%User{}, %{"status" => "retroactive"}, ~w(status))
    assert error in changeset.errors

    changeset = Ecto.Changeset.cast(%User{}, %{"status" => :retroactive}, ~w(status))
    assert error in changeset.errors

    changeset = Ecto.Changeset.cast(%User{}, %{"status" => 4}, ~w(status))
    assert error in changeset.errors

    assert_raise Ecto.ChangeError, custom_error_msg("retroactive"), fn ->
      TestRepo.insert!(%User{status: "retroactive"})
    end

    assert_raise Ecto.ChangeError, custom_error_msg(:retroactive), fn ->
      TestRepo.insert!(%User{status: :retroactive})
    end

    assert_raise Ecto.ChangeError, custom_error_msg(5), fn ->
      TestRepo.insert!(%User{status: 5})
    end

    assert_raise Ecto.ChangeError, fn ->
      TestRepo.insert!(%User{role: 0})
    end

    assert_raise Ecto.ChangeError, fn ->
      TestRepo.insert!(%User{role: :moderator})
    end

    assert_raise Ecto.ChangeError, fn ->
      TestRepo.insert!(%User{role: "moderator"})
    end
  end

  test "reflection" do
    assert StatusEnum.__enum_map__() == [registered: 0, active: 1, inactive: 2, archived: 3]
    assert RoleEnum.__enum_map__() == [user: "string_for_user", admin: "string_for_admin"]

    assert StatusEnum.__valid_values__() == [0, 1, 2, 3,
      :registered, :active, :inactive, :archived,
      "active", "archived", "inactive", "registered"]

    assert Enum.sort(RoleEnum.__valid_values__()) == Enum.sort([
      "string_for_user", "string_for_admin",
      :user, :admin,
      "user", "admin"
    ])
  end

  test "defenum/2 can accept variables" do
    x = 0
    defenum TestEnum, zero: x
  end

  test "determines storage type" do
    assert EctoEnum.storage(user: "user", admin: "admin") == :string
    assert EctoEnum.storage(registered: 0, active: 1, inactive: 2, archived: 3) == :integer
    assert EctoEnum.storage(registered: 0, active: 1, inactive: 2, archived: 3, retroactive: "retroactive") == :indeterminate
  end

  test "raises when storage type is undeterminable" do
    assert_raise EctoEnum.UndeterminableStorageError, fn ->
      defenum TestEnum, integer: 0, string: ""
    end
  end

  def custom_error_msg(value) do
    "`#{inspect value}` is not a valid enum value for `EctoEnumTest.StatusEnum`." <>
    " Valid enum values are `[0, 1, 2, 3, :registered, :active, :inactive, :archived," <>
    " \"active\", \"archived\", \"inactive\", \"registered\"]`"
  end
end
