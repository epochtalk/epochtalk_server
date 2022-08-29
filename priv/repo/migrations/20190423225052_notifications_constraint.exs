defmodule Epoch.Repo.Migrations.NotificationsConstraint do
  use Ecto.Migration

  def up do
    drop constraint(:notifications, :notifications_sender_id_fkey)
    drop constraint(:notifications, :notifications_receiver_id_fkey)
    execute("ALTER TABLE notifications ADD CONSTRAINT notifications_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE")
    execute("ALTER TABLE notifications ADD CONSTRAINT notifications_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE")
  end

  def down do
    drop constraint(:notifications, :notifications_sender_id_fkey)
    drop constraint(:notifications, :notifications_receiver_id_fkey)
    execute("ALTER TABLE notifications ADD CONSTRAINT notifications_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES users(id)")
    execute("ALTER TABLE notifications ADD CONSTRAINT notifications_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES users(id)")
  end
end