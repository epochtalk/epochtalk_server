defmodule Epoch.Repo.Migrations.CreateAds do
  use Ecto.Migration

  def change do
    create table(:ads) do
      add :round, :integer, null: false
      add :html, :text, null: false
      add :css, :text, default: "", null: false
      add :created_at, :timestamp
      add :updated_at, :timestamp
    end
    create index(:ads, [:created_at])
    create index(:ads, [:round])
  end
end
