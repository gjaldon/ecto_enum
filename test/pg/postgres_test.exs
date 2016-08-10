defmodule EctoEnum.PostgresTest do
  use ExUnit.Case, async: false

  import Ecto.Changeset
  import EctoEnum
  defenum StatusEnum, :status, [:registered, :active, :inactive, :archived]

  defmodule User do
    use Ecto.Schema

    schema "users_pg" do
      field :status, StatusEnum
    end
  end

  alias Ecto.Integration.TestRepo

  test "accepts int, atom and string on save" do
    user = TestRepo.insert!(%User{status: :registered})
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

  test "casts binary to atom" do
    %{errors: errors} = cast(%User{}, %{"status" => 3}, ~w(status), [])
    assert {:status, "is invalid"} in errors

    %{changes: changes} = cast(%User{}, %{"status" => "active"}, ~w(status), [])
    assert changes.status == :active

    %{changes: changes} = cast(%User{}, %{"status" => :inactive}, ~w(status), [])
    assert changes.status == :inactive
  end

  test "raises when input is not in the enum map" do
    error = {:status, "is invalid"}

    changeset = cast(%User{}, %{"status" => "retroactive"}, ~w(status), [])
    assert error in changeset.errors

    changeset = cast(%User{}, %{"status" => :retroactive}, ~w(status), [])
    assert error in changeset.errors

    changeset = cast(%User{}, %{"status" => 4}, ~w(status), [])
    assert error in changeset.errors

    assert_raise Ecto.ChangeError, fn ->
      TestRepo.insert!(%User{status: "retroactive"})
    end

    assert_raise Ecto.ChangeError, fn ->
      TestRepo.insert!(%User{status: :retroactive})
    end

    assert_raise Ecto.ChangeError, fn ->
      TestRepo.insert!(%User{status: 5})
    end
  end
end
