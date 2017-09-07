defmodule Ecto.Integration.Migration do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :role, :string
      add :status, :integer
    end
  end
end
