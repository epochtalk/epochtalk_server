defmodule Epoch.Repo.Migrations.MessagesJsonb do
  use Ecto.Migration
  @schema_prefix "messages"

  def up do
    alter table(:private_messages, [prefix: @schema_prefix]) do
      remove :body
      remove :subject
      add :content, :jsonb
    end
  end

  def down do
    alter table(:private_messages, [prefix: @schema_prefix]) do
      remove :content
      add :body, :text, default: "", null: false
      add :subject, :string, null: false
    end
  end
end