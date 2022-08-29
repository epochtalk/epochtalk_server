defmodule Epoch.Repo.Migrations.RolesPermissionsUniqueIndex do
  use Ecto.Migration

  def change do
    create unique_index(:roles_permissions, [:role_id, :permission_path], name: :roles_permissions_unique_index)
  end
end
