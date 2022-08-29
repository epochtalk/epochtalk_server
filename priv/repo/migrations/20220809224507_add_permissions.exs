defmodule Epoch.Repo.Migrations.AddPermissions do
  use Ecto.Migration

  def change do
    create table(:permissions, primary_key: false) do
      add :path, :string, size: 128, primary_key: true
    end
  end
end
