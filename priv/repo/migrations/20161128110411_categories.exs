defmodule Epoch.Repo.Migrations.Categories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string
      add :view_order, :integer
      add :viewable_by, :integer
      add :postable_by, :integer
      add :created_at, :timestamp
      add :imported_at, :timestamp
      add :updated_at, :timestamp
      add :meta, :jsonb
    end
  end
end
