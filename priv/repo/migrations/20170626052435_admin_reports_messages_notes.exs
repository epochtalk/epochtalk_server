defmodule Epoch.Repo.Migrations.AdminReportsMessagesNotes do
  use Ecto.Migration
  
  @schema_prefix "administration"

  def change do
    create table(:reports_messages_notes, [prefix: @schema_prefix]) do
      add :report_id, :bigint, null: false
      add :user_id, :bigint
      add :note, :text, default: "", null: false
      add :created_at, :timestamp
      add :updated_at, :timestamp
    end

    create index(:reports_messages_notes, [:created_at], prefix: @schema_prefix)
    create index(:reports_messages_notes, [:report_id], prefix: @schema_prefix)
  end
end
