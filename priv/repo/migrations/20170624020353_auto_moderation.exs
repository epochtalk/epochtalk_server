defmodule Epoch.Repo.Migrations.AutoModeration do
  use Ecto.Migration

  def change do
    create table(:auto_moderation) do
      add :name, :string, null: false
      add :description, :string, size: 1000
      add :message, :string, size: 1000
      add :conditions, :jsonb, null: false
      add :actions, :jsonb, null: false
      add :options, :jsonb
      add :created_at, :timestamp
      add :updated_at, :timestamp
    end
  end
end
