defmodule Epoch.Repo.Migrations.BoardMapping do
  use Ecto.Migration

  def change do
    create table(:board_mapping, primary_key: false) do
      add :board_id, references(:boards, on_update: :update_all, on_delete: :delete_all), null: false
      add :parent_id, references(:boards, on_update: :update_all, on_delete: :delete_all)
      add :category_id, references(:categories, on_update: :update_all, on_delete: :delete_all)
      add :view_order, :integer, null: false
    end

    create index(:board_mapping, [:board_id])
    create unique_index(:board_mapping, [:board_id, :parent_id])
    create unique_index(:board_mapping, [:board_id, :category_id])
  end
end