defmodule Epoch.Repo.Migrations.ImageExpirations do
  use Ecto.Migration

  def change do
    create table(:image_expirations, primary_key: false) do
      add :expiration, :timestamp
      add :image_url, :string, size: 2000, null: false
    end
    create index(:image_expirations, [:expiration])
    create index(:image_expirations, [:image_url])
  end
end
