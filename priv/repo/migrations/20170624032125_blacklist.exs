defmodule Epoch.Repo.Migrations.Blacklist do
  use Ecto.Migration

  def change do
    create table(:blacklist) do
      add :ip_data, :string, size: 100, null: false
      add :note, :string
    end
  end
end