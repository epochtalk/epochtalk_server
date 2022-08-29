defmodule Epoch.Repo.Migrations.RevertRemoveRoleCascade do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE roles_users DROP CONSTRAINT roles_users_role_id_fkey"
    alter table(:roles_users) do
      modify :role_id, references(:roles, on_delete: :delete_all)
    end
  end

  def down do
    execute "ALTER TABLE roles_users DROP CONSTRAINT roles_users_role_id_fkey"
    alter table(:roles_users) do
      modify :role_id, references(:roles, on_delete: :nothing)
    end
  end

end