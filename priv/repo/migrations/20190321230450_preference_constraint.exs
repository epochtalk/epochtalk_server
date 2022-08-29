defmodule Epoch.Repo.Migrations.PreferenceConstraint do
  use Ecto.Migration
  @schema_prefix "users"

  def up do
    drop constraint(:preferences, :preferences_user_id_fkey, [prefix: @schema_prefix])
    execute(
      "ALTER TABLE users.preferences ADD CONSTRAINT preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE"
    )
  end

  def down do
    drop constraint(:preferences, :preferences_user_id_fkey, [prefix: @schema_prefix])
    execute(
      "ALTER TABLE users.preferences ADD CONSTRAINT preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id)"
    )
  end
end