defmodule Epoch.Repo.Migrations.Configurations do
  use Ecto.Migration

  def change do
    create table(:configurations) do
      add :name, :string
      add :config, :jsonb
    end
    create unique_index(:configurations, [:name])
  end
end