defmodule Epoch.Repo.Migrations.Trust do
  use Ecto.Migration

  def change do
    create table(:trust, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :user_id_trusted, references(:users, on_delete: :delete_all)
      add :type, :smallint
    end

    create table(:trust_boards, primary_key: false) do
      add :board_id, references(:boards, on_delete: :delete_all)
    end

    create table(:trust_feedback) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :reporter_id, references(:users, on_delete: :delete_all)
      add :risked_btc, :float
      add :scammer, :boolean
      add :reference, :text
      add :comments, :text
      add :created_at, :timestamp
    end

    create table(:trust_max_depth, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :max_depth, :smallint, default: 2, null: false
    end

    create unique_index(:trust_boards, [:board_id])
    create unique_index(:trust_max_depth, [:user_id])
    create index(:trust_feedback, [:created_at])
    create index(:trust_feedback, [:reporter_id])
    create index(:trust_feedback, [:scammer])
    create index(:trust_feedback, [:user_id])

    create index(:trust, [:type])
    create index(:trust, [:user_id])
    create index(:trust, [:user_id_trusted])
  end
end
