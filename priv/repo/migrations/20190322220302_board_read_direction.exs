defmodule Epoch.Repo.Migrations.BoardReadDirection do
  use Ecto.Migration

  def change do
    alter table(:boards) do
      add :right_to_left, :boolean, default: false, null: false
    end
  end
end