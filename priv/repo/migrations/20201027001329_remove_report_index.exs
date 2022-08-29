defmodule Epoch.Repo.Migrations.RemoveReportIndex do
  use Ecto.Migration
  @schema_prefix "administration"

  def up do
    drop index(:reports_posts, :offender_post_id_reporter_user_id, prefix: @schema_prefix)
    drop index(:reports_messages, :offender_message_id_reporter_user_id, prefix: @schema_prefix)
  end
  def down do
    create unique_index(:reports_posts, [:offender_post_id, :reporter_user_id], prefix: @schema_prefix)
    create unique_index(:reports_messages, [:offender_message_id, :reporter_user_id], prefix: @schema_prefix)
  end
end