defmodule Epoch.Repo.Migrations.PermissionsUpgrade do
  use Ecto.Migration

  def change do
    rename table(:roles), :permissions, to: :custom_permissions

    alter table(:roles) do
      add :base_permissions, :jsonb
    end
  end
end