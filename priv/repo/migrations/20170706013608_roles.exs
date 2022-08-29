defmodule Epoch.Repo.Migrations.Roles do
  use Ecto.Migration

  def change do
    create table(:roles) do
      add :name, :string, default: "", null: false
      add :description, :text, default: "", null: false
      add :permissions, :jsonb
      add :created_at, :timestamp
      add :updated_at, :timestamp
      add :lookup, :string
      add :priority, :integer
      add :highlight_color, :string
    end

    create table(:roles_users, primary_key: false) do
      add :role_id, references(:roles, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)
    end

    create unique_index(:roles, [:lookup])
  end
end
