Logger.configure(level: :info)
ExUnit.start()

Code.require_file("ecto_migration.exs", __DIR__)

defmodule TestRepo do
  use Ecto.Repo, otp_app: :ecto, adapter: Ecto.Adapters.MyXQL
end

Application.put_env(:ecto, TestRepo,
  pool: Ecto.Adapters.SQL.Sandbox,
  protocol: :tcp,
  username: "root",
  password: "root",
  database: "ecto_test"
)

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
:ok = Ecto.Migrator.up(TestRepo, 0, Ecto.Integration.Migration, log: false)
Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :auto)
Process.flag(:trap_exit, true)
