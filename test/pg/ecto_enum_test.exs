Code.require_file("../ecto_enum_test.exs", __DIR__)

defmodule EctoEnumPostgresTest do
  use ExUnit.Case, async: false

  alias Ecto.Integration.TestRepo

  defmodule User do
    use Ecto.Schema

    @schema_prefix "other_schema"

    schema "users" do
      field(:role, TestEnum)
    end

    def roles() do
      [:admin, :manager, :user]
    end
  end

  test "User Defined Type in PG  works with EctoEnum" do
    error_msg =
      "Value `:non_existent_role` is not a valid enum for `TestEnum`. Valid enums are `[:admin, :manager, :user, \"admin\", \"manager\", \"user\"]`"

    assert_raise Ecto.ChangeError, error_msg, fn ->
      TestRepo.insert!(%User{role: :non_existent_role})
    end

    assert TestRepo.insert!(%User{role: :admin}).role == :admin
  end
end
