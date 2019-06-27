Logger.configure(level: :info)
ExUnit.start()

alias Ecto.Integration.TestRepo

Application.put_env(:ecto, TestRepo,
  adapter: Ecto.Adapters.Postgres,
  url: "ecto://postgres@localhost/ecto_test",
  pool: Ecto.Adapters.SQL.Sandbox
)

defmodule Ecto.Integration.TestRepo do
  use Ecto.Repo, otp_app: :ecto

  def log(_cmd), do: nil
end

# Load up the repository, start it, and run migrations
_ = Ecto.Adapters.Postgres.storage_down(TestRepo.config())
:ok = Ecto.Adapters.Postgres.storage_up(TestRepo.config())

{:ok, pid} = TestRepo.start_link()

Code.require_file("ecto_migration.exs", __DIR__)

:ok = Ecto.Migrator.up(TestRepo, 0, Ecto.Integration.Migration, log: false)
Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)
Process.flag(:trap_exit, true)

:ok = TestRepo.stop(pid)
{:ok, _pid} = TestRepo.start_link()
