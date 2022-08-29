defmodule :"Elixir.Epoch.Repo.Migrations.Ignore-boards-settings" do
  use Ecto.Migration
  @schema_prefix "users"

  def change do
    alter table(:preferences, [prefix: @schema_prefix]) do
      add :ignored_boards, :jsonb, default: fragment("'{\"boards\": []}'::jsonb")
    end
  end
end