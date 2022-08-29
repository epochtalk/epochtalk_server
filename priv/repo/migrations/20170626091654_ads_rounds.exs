defmodule Epoch.Repo.Migrations.AdsRounds do
  use Ecto.Migration
  @schema_prefix "ads"

  def change do
    create table(:rounds, [prefix: @schema_prefix, primary_key: false]) do
      add :round, :serial, primary_key: true
      add :current, :boolean, default: false
      add :start_time, :timestamp
      add :end_time, :timestamp
    end
  end
end
