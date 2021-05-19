defmodule EctoEnumTest do
  use ExUnit.Case

  import EctoEnum
  keywords = [registered: 0, active: 1, inactive: 2, archived: 3]
  defenum StatusEnum, keywords

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field(:status, StatusEnum)
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

  test "casts int and binary to atom" do
    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"status" => "active"}, ~w(status)a)
    assert changes.status == :active

    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"status" => 3}, ~w(status)a)
    assert changes.status == :archived

    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"status" => :inactive}, ~w(status)a)
    assert changes.status == :inactive
  end

  test "raises when input is not in the enum map" do
    error = {:status, {"is invalid", [type: EctoEnumTest.StatusEnum, validation: :cast]}}

    changeset = Ecto.Changeset.cast(%User{}, %{"status" => "retroactive"}, ~w(status)a)
    assert error in changeset.errors

    changeset = Ecto.Changeset.cast(%User{}, %{"status" => :retroactive}, ~w(status)a)
    assert error in changeset.errors

    changeset = Ecto.Changeset.cast(%User{}, %{"status" => 4}, ~w(status)a)
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

  test "default enum's type is integer" do
    assert StatusEnum.type() == :integer
  end

  test "reflection" do
    assert StatusEnum.__enum_map__() == [registered: 0, active: 1, inactive: 2, archived: 3]

    expected_values = [
      0,
      1,
      2,
      3,
      :registered,
      :active,
      :inactive,
      :archived,
      "active",
      "archived",
      "inactive",
      "registered"
    ]

    result = StatusEnum.__valid_values__()

    for expected_value <- expected_values do
      assert expected_value in result
    end
  end

  test "reflection limited to types" do
    expected_values = ["active", "archived", "inactive", "registered"]
    assert Enum.sort(StatusEnum.__valid_values__(:string)) == expected_values

    expected_values = [:active, :archived, :inactive, :registered]
    assert Enum.sort(StatusEnum.__valid_values__(:atom)) == expected_values

    expected_values = [0, 1, 2, 3]
    assert Enum.sort(StatusEnum.__valid_values__(:integer)) == expected_values
  end

  describe "validate_enum/3" do
    test "returns a valid changeset when using a valid field value" do
      changeset =
        %User{}
        |> Ecto.Changeset.change(status: :active)
        |> validate_enum(:status)

      assert changeset.valid?()
      assert [status: :validate_enum] == changeset.validations
    end

    test "returns default error message when enum is invalid" do
      changeset =
        %User{}
        |> Ecto.Changeset.change(status: :wrong)
        |> validate_enum(:status)

      error_msg =
        "Value `:wrong` is not a valid enum for `:status` field. " <>
          "Valid enums are `#{inspect(changeset.types[:status].__valid_values__())}`"

      assert %Ecto.Changeset{errors: [status: {^error_msg, []}]} = changeset
      assert !changeset.valid?()
    end

    test "returns custom error message when enum is invalid" do
      changeset =
        %User{}
        |> Ecto.Changeset.change(status: :wrong)
        |> validate_enum(:status, fn field, value, _ ->
          "`#{inspect(field)}` is invalid. `#{inspect(value)}` is an invalid enum"
        end)

      assert %Ecto.Changeset{
               errors: [status: {"`:status` is invalid. `:wrong` is an invalid enum", []}]
             } = changeset

      assert !changeset.valid?()
    end
  end

  test "defenum/2 can accept variables" do
    x = 0
    defenum TestEnum, zero: x
  end

  test "defenum/2 can accept a list of strings or a keyword list" do
    keywords = [
      registered: "registered",
      active: "active",
      inactive: "inactive",
      archived: "archived"
    ]

    defenum StringStatusEnum, keywords

    assert StringStatusEnum.cast("registered") == {:ok, :registered}

    keywords = [
      "registered",
      "active",
      "inactive",
      "archived"
    ]

    defenum StringStatusEnum, keywords

    assert StringStatusEnum.cast("registered") == {:ok, :registered}
  end

  test "defenum/2 raises when 2nd arg is not a list of strings or a keyword list" do
    assert_raise RuntimeError, "Enum must be a keyword list or a list of strings", fn ->
      defenum StringStatusEnum, [{"not keyword", "list"}]
    end
  end

  test "defenum/3 can accept remote function calls" do
    defenum TestEnum, :role, User.roles()
  end

  keywords = [
    "registered",
    "active",
    "inactive",
    "archived"
  ]

  defenum StringStatusEnum, keywords

  defmodule Account do
    use Ecto.Schema

    schema "accounts" do
      field(:status, StringStatusEnum)
    end

    def roles do
      [:admin, :manager, :user]
    end
  end

  test "string-backed enum accepts int, atom and string on save" do
    user = TestRepo.insert!(%Account{status: "registered"})
    user = TestRepo.get(Account, user.id)
    assert user.status == :registered

    user = Ecto.Changeset.change(user, status: :active)
    user = TestRepo.update!(user)
    assert user.status == :active

    user = Ecto.Changeset.change(user, status: "inactive")
    user = TestRepo.update!(user)
    assert user.status == "inactive"

    user = TestRepo.get(Account, user.id)
    assert user.status == :inactive

    TestRepo.insert!(%Account{status: :archived})
    user = TestRepo.get_by(Account, status: :archived)
    assert user.status == :archived
  end

  test "string-backed enum casts string and atom to atom" do
    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"status" => "active"}, ~w(status)a)
    assert changes.status == :active

    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"status" => :inactive}, ~w(status)a)
    assert changes.status == :inactive
  end

  test "string-backed enum's type is string" do
    assert StringStatusEnum.type() == :string
  end

  test "using EctoEnum for defining an Enum module" do
    defmodule CustomEnum do
      use EctoEnum, ready: 0, set: 1, go: 2
    end

    assert CustomEnum.cast(0) == {:ok, :ready}
  end

  test "using EctoEnum with :type and :enums keys will use EctoEnum.Postgres underneath" do
    defmodule PostgresType do
      use EctoEnum, type: :new_type, enums: [:ready, :set, :go]
    end

    assert PostgresType.cast("ready") == {:ok, :ready}
  end

  test "generates correct t() typespec" do
    assert Code.Typespec.fetch_types(EctoEnum.Typespec.TestModule.StatusEnum) ==
             {:ok,
              [
                type:
                  {:t,
                   {:type, 0, :union,
                    [
                      {:atom, 0, :registered},
                      {:atom, 0, :active},
                      {:atom, 0, :inactive},
                      {:atom, 0, :archived}
                    ]}, []}
              ]}
  end

  test "generates correct t() typespec for postgres types" do
    assert Code.Typespec.fetch_types(EctoEnum.Typespec.TestModule.PGStatusEnum) ==
             {:ok,
              [
                type:
                  {:t,
                   {:type, 0, :union,
                    [
                      {:atom, 0, :registered},
                      {:atom, 0, :active},
                      {:atom, 0, :inactive},
                      {:atom, 0, :archived}
                    ]}, []}
              ]}
  end

  def custom_error_msg(value) do
    "Value `#{inspect(value)}` is not a valid enum for `EctoEnumTest.StatusEnum`." <>
      " Valid enums are `#{inspect(StatusEnum.__valid_values__())}`"
  end
end
