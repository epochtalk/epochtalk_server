defmodule Epoch.Repo.Migrations.PmIgnored do
  use Ecto.Migration
  @schema_prefix "messages"
  def change do
    create table(:ignored, [prefix: @schema_prefix, primary_key: false]) do
      add :user_id, references(:users, on_delete: :delete_all, prefix: "public"), null: false
      add :ignored_user_id, references(:users, on_delete: :delete_all, prefix: "public"), null: false
      add :created_at, :timestamp
    end

    alter table(:preferences, [prefix: "users"]) do
      add :email_messages, :boolean, default: true
    end

    create index(:ignored, [:user_id], prefix: @schema_prefix)
    create index(:ignored, [:ignored_user_id], prefix: @schema_prefix)
    create unique_index(:ignored, [:user_id, :ignored_user_id], prefix: @schema_prefix)
  end
end