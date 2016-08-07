defmodule Ecto.Integration.Migration do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE status AS ENUM ('registered', 'active', 'inactive', 'archived')"
    create table(:users) do
      add :status, :status
    end
  end
end
