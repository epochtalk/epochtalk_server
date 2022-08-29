defmodule Epoch.Repo.Migrations.UserTimezoneOffset do
  use Ecto.Migration
  @schema_prefix "users"

  def change do
    alter table(:preferences, [prefix: @schema_prefix]) do
      add :timezone_offset, :string, default: ""
    end
  end
end