defmodule Epoch.Repo.Migrations.PrivateMessages do
  use Ecto.Migration

  def change do
    create table(:private_conversations) do
      add :created_at, :timestamp
    end

    create table(:private_messages) do
      add :conversation_id, references(:private_conversations, on_delete: :delete_all), null: false
      add :sender_id, references(:users, on_delete: :delete_all)
      add :receiver_id, references(:users, on_delete: :delete_all)
      add :copied_ids, {:array, :bigint}
      add :body, :text, default: "", null: false
      add :created_at, :timestamp
      add :viewed, :boolean, default: false
    end

    create index(:private_messages, [:conversation_id])
    create index(:private_messages, [:sender_id])
    create index(:private_messages, [:receiver_id])
    create index(:private_messages, [:created_at])
  end
end
