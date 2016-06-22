defmodule Ecto.Integration.Migration do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :status, :integer
    end

    create table(:posts) do
      add :categories, {:array, :integer}
    end
  end
end
