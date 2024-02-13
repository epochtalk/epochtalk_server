defmodule EpochtalkServer.Repo.Migrations.RolesPermissionsPermissionPathCascade do
  use Ecto.Migration

  def up do
    drop constraint(:roles_permissions, "roles_permissions_permission_path_fkey")
    alter table(:roles_permissions) do
      modify :permission_path, references(:permissions, column: :path, type: :string, on_delete: :delete_all), null: false
    end
  end
  def down do
    drop constraint(:roles_permissions, "roles_permissions_permission_path_fkey")
    alter table(:roles_permissions) do
      modify :permission_path, references(:permissions, column: :path, type: :string, on_delete: :nothing), null: false
    end
  end
end
