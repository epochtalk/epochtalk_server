defmodule Epoch.Repo.Migrations.MessagesSchema do
  use Ecto.Migration

  def up do
    execute "CREATE SCHEMA messages"
    execute "ALTER TABLE private_messages SET SCHEMA messages;"
    execute "ALTER TABLE private_conversations SET SCHEMA messages;"
  end

  def down do
    execute "ALTER TABLE messages.private_messages SET SCHEMA public;"
    execute "ALTER TABLE messages.private_conversations SET SCHEMA public;"
    execute "DROP SCHEMA messages"
  end
end