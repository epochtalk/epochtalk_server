defmodule Epoch.Repo.Migrations.PostMetadata do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :metadata, :jsonb
    end
  end
end