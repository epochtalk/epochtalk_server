defmodule Epoch.Repo.Migrations.ModerationLog do
  use Ecto.Migration

  def change do
    create table(:moderation_log, primary_key: false) do
      add :mod_username, :string, size: 40, null: false
      add :mod_id, :bigint
      add :mod_ip, :string
      add :action_api_url, :varchar, size: 2000, null: false
      add :action_api_method, :varchar, size: 25, null: false
      add :action_obj, :jsonb, null: false
      add :action_taken_at, :timestamp, null: false
      add :action_type, :moderation_action_type, null: false
      add :action_display_text, :text, null: false
      add :action_display_url, :string
    end

    create index(:moderation_log, [:action_api_method])
    create index(:moderation_log, [:action_api_url])
    create index(:moderation_log, [:action_taken_at])
    create index(:moderation_log, [:action_type])
    create index(:moderation_log, [:mod_id])
    create index(:moderation_log, [:mod_ip])
    create index(:moderation_log, [:mod_username])
  end
end
