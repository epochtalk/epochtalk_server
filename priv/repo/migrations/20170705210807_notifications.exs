defmodule Epoch.Repo.Migrations.Notifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :sender_id, references(:users), null: false
      add :receiver_id, references(:users), null: false
      add :data, :jsonb
      add :created_at, :timestamp
      add :viewed, :boolean, default: false
      add :type, :string
    end

    create index(:notifications, [:type])
  end
end
