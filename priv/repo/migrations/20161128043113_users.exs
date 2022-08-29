defmodule Epoch.Repo.Migrations.Users do
  use Ecto.Migration

  def up do
    create table(:users) do
      add :email, :citext, null: false
      add :username, :citext, null: false
      add :passhash, :string
      add :confirmation_token, :string
      add :reset_token, :string
      add :reset_expiration, :timestamp
      add :created_at, :timestamp
      add :imported_at, :timestamp
      add :updated_at, :timestamp
      add :deleted, :boolean, default: false
      add :malicious_score, :integer
    end

    create unique_index(:users, [:username])
    create unique_index(:users, [:email])

    create table(:user_activity) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :current_period_start, :timestamp
      add :current_period_offset, :timestamp
      add :remaining_period_activity, :integer, default: 14, null: false
      add :total_activity, :integer, default: 0, null: false
    end

    create index(:user_activity, [:total_activity])
    create unique_index(:user_activity, [:user_id])

    create table(:user_notes) do
      add :user_id, references(:users,  on_delete: :delete_all)
      add :author_id, references(:users, on_delete: :delete_all)
      add :note, :text, default: "", null: false
      add :created_at, :timestamp
      add :updated_at, :timestamp
    end

    create index(:user_notes, [:created_at])
    create index(:user_notes, [:user_id])
  end
end
