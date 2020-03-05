Logger.configure(level: :info)
ExUnit.start()
alias Ecto.Integration.TestRepo
alias Ecto.Integration.PoolRepo

Code.require_file("ecto_migration.exs", __DIR__)

Application.put_env(:ecto, TestRepo,
  url: "ecto://root@localhost/ecto_test",
  pool: Ecto.Adapters.SQL.Sandbox
)

defmodule TestRepo do
  use Ecto.Repo, otp_app: :ecto, adapter: Ecto.Adapters.MyXQL
end

Application.put_env(:ecto, PoolRepo,
  adapter: Ecto.Adapters.MyXQL,
  url: "ecto://root@localhost/ecto_test",
  pool_size: 10
)

defmodule PoolRepo do
  use Ecto.Repo, otp_app: :ecto, adapter: Ecto.Adapters.MyXQL

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

{:ok, _} = Ecto.Adapters.MyXQL.ensure_all_started(TestRepo, :temporary)

# Load up the repository, start it, and run migrations
_ = Ecto.Adapters.MyXQL.storage_down(TestRepo.config())
:ok = Ecto.Adapters.MyXQL.storage_up(TestRepo.config())

{:ok, _pid} = TestRepo.start_link()
# {:ok, _pid} = PoolRepo.start_link
:ok = Ecto.Migrator.up(TestRepo, 0, Ecto.Integration.Migration, log: false)
Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :auto)
Process.flag(:trap_exit, true)
