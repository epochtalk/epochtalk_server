defmodule Epoch.Repo.Migrations.NumericMaliciousScore do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :malicious_score, :numeric
    end
  end
end