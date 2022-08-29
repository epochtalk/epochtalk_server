defmodule Epoch.Repo.Migrations.IgnoreNewbies do
  use Ecto.Migration
  @schema_prefix "users"
  def change do
    alter table(:preferences, [prefix: @schema_prefix]) do
      add :ignore_newbies, :boolean, default: true
    end
  end
end