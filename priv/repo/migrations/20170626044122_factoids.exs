defmodule Epoch.Repo.Migrations.Factoids do
  use Ecto.Migration

  # move to after admin
  def change do
    create table(:factoids) do
      add :text, :text, null: false
      add :enabled, :boolean, default: true
      add :created_at, :timestamp
      add :updated_at, :timestamp
    end

    create index(:factoids, [:created_at])
    create index(:factoids, [:enabled])
  end
end
