defmodule Epoch.Repo.Migrations.CreateRolesPermissions do
  use Ecto.Migration

  def change do
    create table(:roles_permissions, primary_key: false) do
      add :role_id, references(:roles, column: :id, type: :integer, on_delete: :delete_all), null: false
      add :permission_path, references(:permissions, column: :path, type: :string), null: false
      add :value, :boolean
      add :modified, :boolean
    end
  end
end
