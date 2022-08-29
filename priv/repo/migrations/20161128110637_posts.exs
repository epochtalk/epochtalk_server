defmodule Epoch.Repo.Migrations.Posts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :thread_id, references(:threads, on_delete: :delete_all, on_update: :update_all)
      add :user_id, references(:users, on_delete: :delete_all, on_update: :update_all)
      add :content, :jsonb
      add :deleted, :boolean
      add :locked, :boolean
      add :position, :integer
      add :created_at, :timestamp
      add :imported_at, :timestamp
      add :updated_at, :timestamp
    end
    
    create index(:posts, [:thread_id])
    create index(:posts, [:user_id])
    create index(:posts, [:thread_id, :position])
    create index(:posts, [:thread_id, :created_at])
    create index(:posts, [:user_id, :created_at])
    create index(:posts, [:thread_id, :user_id])
  end
end
