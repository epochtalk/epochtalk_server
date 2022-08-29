defmodule Epoch.Repo.Migrations.RolePermissionsPriorityRestrictions do
  use Ecto.Migration

  def change do
    alter table(:roles) do
      remove :base_permissions
      remove :custom_permissions

      add :permissions, :map
      add :priority_restrictions, {:array, :integer}
    end
  end
end
