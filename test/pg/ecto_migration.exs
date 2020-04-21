defmodule Ecto.Integration.SetupMigration do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:status, :integer)
    end

    create table(:accounts) do
      add(:status, :string)
    end

    execute("CREATE TYPE status AS ENUM ('registered', 'active', 'inactive', 'archived')")

    create table(:users_pg) do
      add(:status, :status)
    end
  end
end

import EctoEnum
defenum(TestEnumOld, :role, [:admin, :user], schema: "other_schema")
defenum(TestEnum, :role, [:admin, :manager, :user], schema: "other_schema")

defmodule Ecto.Integration.TestEnumMigration do
  use Ecto.Migration

  def up do
    TestEnumOld.create_type()

    create table("users", prefix: "other_schema") do
      add(:role, TestEnumOld.type())
    end
  end

  def down do
    drop(table("users", prefix: "other_schema"))
    TestEnumOld.drop_type()
  end
end

defmodule Ecto.Integration.TestAlterEnumMigration do
  use Ecto.Migration

  def change do
    TestEnum.alter_type()
  end
end
