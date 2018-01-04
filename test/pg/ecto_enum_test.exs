defmodule EctoEnumTest do
  use ExUnit.Case

  import EctoEnum
  keywords = [registered: 0, active: 1, inactive: 2, archived: 3]
  defenum StatusEnum, keywords

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field :status, StatusEnum
    end

    def roles do
      [:admin, :manager, :user]
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
  end

  test "casts int and binary to atom" do
    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"status" => "active"}, ~w(status))
    assert changes.status == :active

    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"status" => 3}, ~w(status))
    assert changes.status == :archived

    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"status" => :inactive}, ~w(status))
    assert changes.status == :inactive
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
  end

  test "reflection" do
    assert StatusEnum.__enum_map__() == [registered: 0, active: 1, inactive: 2, archived: 3]
    assert StatusEnum.__valid_values__() == [0, 1, 2, 3,
      :registered, :active, :inactive, :archived,
      "active", "archived", "inactive", "registered"]
  end

  describe "validate_enum/3" do

    test "returns a valid changeset when using a valid field value" do
      changeset = %User{}
      |> Ecto.Changeset.change(status: :active)
      |> validate_enum(:status)

      assert changeset.valid?()
      assert [status: :validate_enum] == changeset.validations
    end

    test "returns default error message when enum is invalid" do
      changeset = %User{}
      |> Ecto.Changeset.change(status: :wrong)
      |> validate_enum(:status)

      assert %Ecto.Changeset{errors: [status: {"Value `wrong` is not member of status enum", []}]} = changeset
      assert !changeset.valid?()
    end

    test "returns custom error message when enum is invalid" do
      changeset = %User{}
      |> Ecto.Changeset.change(status: :wrong)
      |> validate_enum(:status, fn(field, value) -> "#{field} is not ok, I can't find #{value}" end)

      assert %Ecto.Changeset{errors: [status: {"status is not ok, I can't find wrong", []}]} = changeset
      assert !changeset.valid?()
    end

  end

  test "defenum/2 can accept variables" do
    x = 0
    defenum TestEnum, zero: x
  end

  test "defenum/3 can accept remote function calls" do
    defenum TestEnum, :role, User.roles()
  end

  def custom_error_msg(value) do
    "`#{inspect value}` is not a valid enum value for `EctoEnumTest.StatusEnum`." <>
    " Valid enum values are `[0, 1, 2, 3, :registered, :active, :inactive, :archived," <>
    " \"active\", \"archived\", \"inactive\", \"registered\"]`"
  end
end
