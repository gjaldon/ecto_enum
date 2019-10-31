Logger.configure(level: :info)
ExUnit.start()

alias Ecto.Integration.TestRepo

Application.put_env(:ecto, TestRepo,
  url: "ecto://postgres@localhost/ecto_test",
  pool: Ecto.Adapters.SQL.Sandbox
)

defmodule Ecto.Integration.TestRepo do
  use Ecto.Repo, otp_app: :ecto, adapter: Ecto.Adapters.Postgres

  def log(_cmd), do: nil
end

# Load up the repository, start it, and run migrations
_ = Ecto.Adapters.Postgres.storage_down(TestRepo.config())
:ok = Ecto.Adapters.Postgres.storage_up(TestRepo.config())

{:ok, _pid} = TestRepo.start_link()

Code.require_file("ecto_migration.exs", __DIR__)

Ecto.Adapters.SQL.query!(TestRepo, "CREATE SCHEMA other_schema", [])

:ok = Ecto.Migrator.up(TestRepo, 0, Ecto.Integration.SetupMigration, log: false)
:ok = Ecto.Migrator.up(TestRepo, 1, Ecto.Integration.TestEnumMigration, log: false)

Ecto.Adapters.SQL.Sandbox.mode(TestRepo, {:shared, self()})
