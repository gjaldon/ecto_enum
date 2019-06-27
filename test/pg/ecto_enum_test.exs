Code.require_file("../ecto_enum_test.exs", __DIR__)

defmodule EctoEnumPostgresTest do
  use ExUnit.Case
  import EctoEnum

  alias Ecto.Integration.TestRepo

  test "create_type/1 can accept schema and creates a type in that schema" do
    Ecto.Adapters.SQL.query!(TestRepo, "CREATE SCHEMA other_schema", [])

    defenum(TestEnum, :role, [:admin, :manager, :user], schema: "other_schema")

    defmodule TestMigration do
      use Ecto.Migration

      def up do
        TestEnum.create_type()

        create table("users", prefix: "other_schema") do
          add(:role, TestEnum.type())
        end
      end

      def down do
        drop(table("users", prefix: "other_schema"))
        TestEnum.drop_type()
      end
    end

    assert :ok = Ecto.Migrator.up(TestRepo, 1, TestMigration, log: false)

    defmodule User do
      use Ecto.Schema

      schema "other_schema.users" do
        field(:role, TestEnum)
      end

      def roles() do
        [:admin, :manager, :user]
      end
    end

    Ecto.Migrator.down(TestRepo, 1, TestMigration, log: false)
  end
end
