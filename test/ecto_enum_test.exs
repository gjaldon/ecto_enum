defmodule EctoEnumTest do
  use ExUnit.Case

  import Ecto.Query
  import Ecto.Changeset
  import EctoEnum, only: [defenum: 2]

  @valid_enum_map %{
    0 => "registered", "registered" => 0,
    1 => "active"    , "active"     => 1,
    2 => "inactive"  , "inactive"   => 2,
    3 => "archived"  , "archived"   => 3,
  }

  defmodule Status do
    use EctoEnum

    enum ~w(registered active inactive archived)
  end

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field :status, Status
    end
  end

  defmodule Categories do
    use EctoEnum, multiple: true

    enum ~w(science biology modernity)a
  end

  defmodule Post do
    use Ecto.Schema

    schema "posts" do
      field :categories, Categories
    end
  end

  alias Ecto.Integration.TestRepo

  test "types" do
    assert Ecto.Type.type(Status    ) == :integer
    assert Ecto.Type.type(Categories) == {:array, :integer}
  end

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

  test "accepts list of int, atom and string on save" do
    post = TestRepo.insert!(%Post{categories: [0, 2]})
    post = TestRepo.get(Post, post.id)
    assert post.categories == [:science, :modernity]

    post = Ecto.Changeset.change(post, categories: [:biology])
    post = TestRepo.update! post
    assert post.categories == [:biology]

    post = Ecto.Changeset.change(post, categories: [:biology, "science"])
    post = TestRepo.update!(post)
    assert post.categories == [:biology, "science"]

    post = TestRepo.get(Post, post.id)
    assert post.categories == [:biology, :science]

    categories = Categories.to_integer(["biology"])
    post = Post
    |> where([p], fragment("? @> ?", p.categories, ^categories))
    |> TestRepo.one
    assert post.categories == [:biology, :science]
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
    assert Status.__enum_map__() == ~w(registered active inactive archived)
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
    assert Status.to_integer("registered") == 0
    assert Status.to_integer("active"    ) == 1
    assert Status.to_integer("inactive"  ) == 2
    assert Status.to_integer("archived"  ) == 3
    assert Status.to_integer("_invalid"  ) == :error
    assert Status.to_integer("Active"    ) == :error
  end

  test "should value from atom" do
    assert Status.to_integer(:registered) == 0
    assert Status.to_integer(:active    ) == 1
    assert Status.to_integer(:inactive  ) == 2
    assert Status.to_integer(:archived  ) == 3
    assert Status.to_integer(:_invalid  ) == :error
    assert Status.to_integer(:Active    ) == :error
  end

  test "should value from list of atom" do
    # science biology modernity
    assert Categories.to_integer([:science,  :modernity]) == [0, 2]
    assert Categories.to_integer([:_invalid, :modernity]) == :error
    assert Categories.to_integer([:Active,   :modernity]) == :error
    assert Categories.to_integer([:Active,   :_invalid ]) == :error
  end

  test "should atom from integer" do
    assert Status.to_atom(0) == :registered
    assert Status.to_atom(1) == :active
    assert Status.to_atom(2) == :inactive
    assert Status.to_atom(3) == :archived
    assert Status.to_atom(4) == :error
  end

  test "should atom from list of integer" do
    assert Categories.to_atom([0, 2, 1]) == [:science, :modernity, :biology]
    assert Categories.to_atom([2, 1, 3]) == :error
    assert Categories.to_atom([0, 4, 2]) == :error
  end

end
