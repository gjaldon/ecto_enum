defmodule EctoEnumTest do
  use ExUnit.Case

  import Ecto.Changeset
  import EctoEnum, only: [defenum: 2]

  @valid_enum_map %{
    0 => "registered", "registered" => 0,
    1 => "active"    , "active"     => 1,
    2 => "inactive"  , "inactive"   => 2,
    3 => "archived"  , "archived"   => 3,
  }

  defmodule StatusEnum do
    use EctoEnum

    enum ~w(registered active inactive archived)
  end

  defmodule User do
    use Ecto.Schema

    schema "users" do
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
  end

  test "casts int and binary to atom" do
    %{changes: changes} = cast(%User{}, %{"status" => "active"}, ~w(status), [])
    assert changes.status == :active

    %{changes: changes} = cast(%User{}, %{"status" => 3}, ~w(status), [])
    assert changes.status == :archived

    %{changes: changes} = cast(%User{}, %{"status" => :inactive}, ~w(status), [])
    assert changes.status == :inactive
  end

  test "should chanset errors when input is not in the enum map" do
    error = {:status, "is invalid"}

    changeset = cast(%User{}, %{"status" => "retroactive"}, ~w(status), [])
    assert changeset.changes == %{}
    assert error in changeset.errors

    changeset = cast(%User{}, %{"status" => :retroactive}, ~w(status), [])
    assert changeset.changes == %{}
    assert error in changeset.errors

    changeset = cast(%User{}, %{"status" => 4}, ~w(status), [])
    assert changeset.changes == %{}
    assert error in changeset.errors
  end

  test "raises when input is not in the enum map" do
    assert_raise EctoEnum.Error, fn ->
      TestRepo.insert!(%User{status: "retroactive"})
    end

    assert_raise EctoEnum.Error, fn ->
      TestRepo.insert!(%User{status: :retroactive})
    end

    assert_raise EctoEnum.Error, fn ->
      TestRepo.insert!(%User{status: 5})
    end
  end

  test "reflection" do
    assert StatusEnum.__enum_map__() == ~w(registered active inactive archived)
  end

  test "defenum/2 can accept variables" do
    x = 0
    defenum TestEnum, zero: x
    assert TestEnum.__enum_map__() == [zero: 0]
  end

  test "normalize enums to double map" do
    assert @valid_enum_map == EctoEnum.enums_to_map([registered: 0, active: 1, inactive: 2, archived: 3])
    assert @valid_enum_map == EctoEnum.enums_to_map(~w(registered active inactive archived))
    assert @valid_enum_map == EctoEnum.enums_to_map(~w(registered active inactive archived)a)
  end

  test "should value from string" do
    assert EctoEnum.to_integer("registered", @valid_enum_map) == 0
    assert EctoEnum.to_integer("active"    , @valid_enum_map) == 1
    assert EctoEnum.to_integer("inactive"  , @valid_enum_map) == 2
    assert EctoEnum.to_integer("archived"  , @valid_enum_map) == 3
    assert EctoEnum.to_integer("_invalid"  , @valid_enum_map) == :error
    assert EctoEnum.to_integer("Active"    , @valid_enum_map) == :error
  end

  test "should value from atom" do
    assert EctoEnum.to_integer(:registered, @valid_enum_map) == 0
    assert EctoEnum.to_integer(:active    , @valid_enum_map) == 1
    assert EctoEnum.to_integer(:inactive  , @valid_enum_map) == 2
    assert EctoEnum.to_integer(:archived  , @valid_enum_map) == 3
    assert EctoEnum.to_integer(:_invalid  , @valid_enum_map) == :error
    assert EctoEnum.to_integer(:Active    , @valid_enum_map) == :error
  end

  test "should atom from integer" do
    assert EctoEnum.to_atom(0, @valid_enum_map) == :registered
    assert EctoEnum.to_atom(1, @valid_enum_map) == :active
    assert EctoEnum.to_atom(2, @valid_enum_map) == :inactive
    assert EctoEnum.to_atom(3, @valid_enum_map) == :archived
    assert EctoEnum.to_atom(4, @valid_enum_map) == :error
  end

end
