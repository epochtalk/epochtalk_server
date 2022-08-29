defmodule Epoch.Repo.Migrations.Invitations do
  use Ecto.Migration

  def change do
    create table(:invitations, primary_key: false) do
      add :email, :citext, null: false
      add :hash, :string, null: false
      add :created_at, :timestamp, null: false
    end

    # CONSTRAINT invitations_email_check CHECK ((length((email)::text) <= 255))
    create constraint(:invitations, :invitations_email_check, check: "(length((email)::text) <= 255)")
    create index(:invitations, [:hash])
    create unique_index(:invitations, [:email])
    create index(:invitations, [:created_at])
  end
end
