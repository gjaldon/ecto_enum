defmodule EctoEnum.PostgresTest do
  use ExUnit.Case, async: false

  import EctoEnum
  defenum StatusEnum, :status, [:registered, :active, :inactive, :archived, :"on-hold"]

  defmodule User do
    use Ecto.Schema

    schema "users_pg" do
      field(:status, StatusEnum)
    end
  end

  alias Ecto.Integration.TestRepo

  test "accepts atom and string on save" do
    user = TestRepo.insert!(%User{status: :registered})
    user = TestRepo.get(User, user.id)
    assert user.status == :registered

    user = Ecto.Changeset.change(user, status: :active)
    user = TestRepo.update!(user)
    assert user.status == :active

    user = Ecto.Changeset.change(user, status: "inactive")
    user = TestRepo.update!(user)
    assert user.status == "inactive"

    user = TestRepo.get(User, user.id)
    assert user.status == :inactive

    TestRepo.insert!(%User{status: :archived})
    user = TestRepo.get_by(User, status: :archived)
    assert user.status == :archived
  end

  test "casts binary to atom" do
    %{errors: errors} = Ecto.Changeset.cast(%User{}, %{"status" => 3}, ~w(status))
    error = {:status, {"is invalid", [type: EctoEnum.PostgresTest.StatusEnum, validation: :cast]}}
    assert error in errors

    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"status" => "active"}, ~w(status))
    assert changes.status == :active

    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"status" => :inactive}, ~w(status))
    assert changes.status == :inactive
  end

  test "raises when input is not in the enum map" do
    error = {:status, {"is invalid", [type: EctoEnum.PostgresTest.StatusEnum, validation: :cast]}}

    changeset = Ecto.Changeset.cast(%User{}, %{"status" => "retroactive"}, ~w(status))
    assert error in changeset.errors

    changeset = Ecto.Changeset.cast(%User{}, %{"status" => :retroactive}, ~w(status))
    assert error in changeset.errors

    changeset = Ecto.Changeset.cast(%User{}, %{"status" => 4}, ~w(status))
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

  test "using EctoEnum.Postgres for defining an Enum module" do
    defmodule NewType do
      use EctoEnum.Postgres, type: :new_type, enums: [:ready, :set, :go]
    end

    assert NewType.cast("ready") == {:ok, :ready}
  end

  test "provides getter macros for the keys that match to values of enum" do
    require StatusEnum

    assert StatusEnum.registered() == :registered
    assert StatusEnum.on_hold() == :"on-hold"
  end

  defmodule Light do
    import EctoEnum

    defenum(LightEnum, :traffic_light_enum, [:green, :red, :yellow])
  end

  defmodule Traffic do
    require Light.LightEnum
    def action(Light.LightEnum.green()), do: "go!"
    def action(Light.LightEnum.red()), do: "stop!"
    def action(Light.LightEnum.yellow()), do: "slow down!"
  end

  test "getter macros should work in pattern matches" do
    require Light.LightEnum

    assert Traffic.action(Light.LightEnum.green()) == "go!"
    assert Traffic.action(Light.LightEnum.red()) == "stop!"
    assert Traffic.action(Light.LightEnum.yellow()) == "slow down!"
  end
end
