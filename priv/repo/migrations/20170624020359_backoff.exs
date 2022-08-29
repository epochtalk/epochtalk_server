defmodule Epoch.Repo.Migrations.Backoff do
  use Ecto.Migration

  def change do
    create table(:backoff, primary_key: false) do
      add :ip, :string, size: 40
      add :route, :string, size: 255
      add :method, :string, size: 15
      add :created_at, :timestamp
    end

    create index(:backoff, [:ip, :route, :method])
  end
end
