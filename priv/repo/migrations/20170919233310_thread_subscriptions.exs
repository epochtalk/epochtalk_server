defmodule Epoch.Repo.Migrations.ThreadSubscriptions do
  use Ecto.Migration
  @schema_prefix "users"

  def change do

    create table(:thread_subscriptions, [prefix: @schema_prefix, primary_key: false]) do
      add :user_id, :bigint, null: false
      add :thread_id, :bigint, null: false
    end

    create index(:thread_subscriptions, [:user_id], prefix: @schema_prefix)
    create index(:thread_subscriptions, [:thread_id], prefix: @schema_prefix)
    create unique_index(:thread_subscriptions, [:user_id, :thread_id], prefix: @schema_prefix)

    alter table(:preferences, [prefix: @schema_prefix]) do
      add :notify_replied_threads, :boolean, default: true
    end

    drop index(:preferences, [:user_id], prefix: @schema_prefix)
    create unique_index(:preferences, [:user_id], prefix: @schema_prefix)

  end
end