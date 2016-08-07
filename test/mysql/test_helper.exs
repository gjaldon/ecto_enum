ExUnit.start()

Code.require_file "ecto_migration.exs", __DIR__

Application.put_env(:ecto, Ecto.Integration.TestRepo,
  adapter: Ecto.Adapters.MySQL,
  url: "ecto://root@localhost/ecto_test",
  pool: Ecto.Adapters.SQL.Sandbox)

defmodule Ecto.Integration.TestRepo do
  use Ecto.Repo, otp_app: :ecto
end

Application.put_env(:ecto, Ecto.Integration.PoolRepo,
  adapter: Ecto.Adapters.MySQL,
  url: "ecto://root@localhost/ecto_test",
  pool_size: 10)

defmodule Ecto.Integration.PoolRepo do
  use Ecto.Repo, otp_app: :ecto

  def create_prefix(prefix) do
    "create database #{prefix}"
  end

  def drop_prefix(prefix) do
    "drop database #{prefix}"
  end
end


defmodule Ecto.Integration.Case do
  use ExUnit.CaseTemplate

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)
  end
end

alias Ecto.Integration.TestRepo
alias Ecto.Integration.PoolRepo

{:ok, _} = Ecto.Adapters.MySQL.ensure_all_started(TestRepo, :temporary)

# Load up the repository, start it, and run migrations
_   = Ecto.Adapters.MySQL.storage_down(TestRepo.config)
:ok = Ecto.Adapters.MySQL.storage_up(TestRepo.config)

{:ok, _pid} = TestRepo.start_link
{:ok, _pid} = PoolRepo.start_link
:ok = Ecto.Migrator.up(TestRepo, 0, Ecto.Integration.Migration, log: false)
Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)
Process.flag(:trap_exit, true)

