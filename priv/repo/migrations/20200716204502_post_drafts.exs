defmodule Epoch.Repo.Migrations.PostDrafts do
  use Ecto.Migration
  @schema_prefix "posts"

  def up do
    execute "CREATE SCHEMA #{@schema_prefix}"

    create table(:user_drafts, [prefix: @schema_prefix, primary_key: false]) do
      add :user_id, references(:users, on_delete: :delete_all, prefix: "public"), null: false
      add :draft, :text
      add :updated_at, :timestamp
    end
    create unique_index(:user_drafts, [:user_id], prefix: @schema_prefix)
  end

  def down do
    drop table(:user_drafts, [prefix: @schema_prefix])
    execute "DROP SCHEMA #{@schema_prefix}"
  end
end