defmodule Ecto.Integration.Migration do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:status, :integer)
    end

    create table(:accounts) do
      add(:status, :string)
    end
  end
end
