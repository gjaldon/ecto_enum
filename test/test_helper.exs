ExUnit.start()

alias Ecto.Integration.TestRepo

Application.put_env(:ecto, TestRepo,
  adapter: Ecto.Adapters.Postgres,
  url: "ecto://postgres:postgres@localhost/ecto_test",
  pool: Ecto.Adapters.SQL.Sandbox)

defmodule Ecto.Integration.TestRepo do
  use Ecto.Repo, otp_app: :ecto

  def log(_cmd), do: nil
end

# Load up the repository, start it, and run migrations
_   = Ecto.Storage.down(TestRepo)
:ok = Ecto.Storage.up(TestRepo)

{:ok, _pid} = TestRepo.start_link

Code.require_file "ecto_migration.exs", __DIR__

:ok = Ecto.Migrator.up(TestRepo, 0, Ecto.Integration.Migration, log: false)
Process.flag(:trap_exit, true)

# Clean up after our selves so that successive runs don't break.
System.at_exit fn
  0 -> :ok = Ecto.Storage.down(TestRepo)
  _ -> :ok
end
