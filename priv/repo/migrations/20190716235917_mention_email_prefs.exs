defmodule Epoch.Repo.Migrations.MentionEmailPrefs do
  use Ecto.Migration
  @schema_prefix "users"

  def change do
    alter table(:preferences, [prefix: @schema_prefix]) do
      add :email_mentions, :boolean, default: true
    end
  end
end