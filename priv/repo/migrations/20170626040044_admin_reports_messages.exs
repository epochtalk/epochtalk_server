defmodule Epoch.Repo.Migrations.AdminReportsMessages do
  use Ecto.Migration

  @schema_prefix "administration"

  def change do
    create table(:reports_messages, [prefix: @schema_prefix]) do
      add :status, :report_status_type, default: fragment("'Pending'::report_status_type"), null: false
      add :reporter_user_id, :bigint
      add :reporter_reason, :text, default: "", null: false
      add :reviewer_user_id, :bigint
      add :offender_message_id, :bigint, null: false
      add :created_at, :timestamp
      add :updated_at, :timestamp
    end

    create unique_index(:reports_messages, [:offender_message_id, :reporter_user_id], prefix: @schema_prefix)
    create index(:reports_messages, [:created_at], prefix: @schema_prefix)
  end
end
