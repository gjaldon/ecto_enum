defmodule EctoEnumTest do
  use ExUnit.Case

  import Ecto.Changeset
  import Ecto.Enum
  defenum StatusEnum, registered: 0, active: 1, inactive: 2, archived: 3

  defmodule User do
    use Ecto.Model

    schema "users" do
      field :status, StatusEnum
    end
  end

  alias Ecto.Integration.TestRepo

  test "accepts int, atom and string on save" do
    user = TestRepo.insert!(%User{status: 0})
    user = TestRepo.get(User, user.id)
    assert user.status == :registered

    user = TestRepo.update!(%{user|status: :active})
    user = TestRepo.get(User, user.id)
    assert user.status == :active

    user = TestRepo.update!(%{user|status: "inactive"})
    user = TestRepo.get(User, user.id)
    assert user.status == :inactive

    TestRepo.insert!(%User{status: :archived})
    user = TestRepo.get_by(User, status: :archived)
    assert user.status == :archived
  end

  test "casts int and binary to atom" do
    %{changes: changes} = cast(%User{}, %{"status" => "active"}, ~w(status), [])
    assert changes.status == :active

    %{changes: changes} = cast(%User{}, %{"status" => 3}, ~w(status), [])
    assert changes.status == :archived

    %{changes: changes} = cast(%User{}, %{"status" => :inactive}, ~w(status), [])
    assert changes.status == :inactive
  end

  test "raises when input is not in the enum map" do
    assert_raise Elixir.Ecto.Enum.Error, fn ->
      cast(%User{}, %{"status" => "retroactive"}, ~w(status), [])
    end

    assert_raise Elixir.Ecto.Enum.Error, fn ->
      cast(%User{}, %{"status" => :retroactive}, ~w(status), [])
    end

    assert_raise Elixir.Ecto.Enum.Error, fn ->
      cast(%User{}, %{"status" => 4}, ~w(status), [])
    end

    assert_raise Elixir.Ecto.Enum.Error, fn ->
      TestRepo.insert!(%User{status: "retroactive"})
    end

    assert_raise Elixir.Ecto.Enum.Error, fn ->
      TestRepo.insert!(%User{status: :retroactive})
    end

    assert_raise Elixir.Ecto.Enum.Error, fn ->
      TestRepo.insert!(%User{status: 5})
    end
  end

  test "reflection" do
    assert StatusEnum.__enum_map__() == [registered: 0, active: 1, inactive: 2, archived: 3]
  end
end

# TODO: configure to return either string or atom
