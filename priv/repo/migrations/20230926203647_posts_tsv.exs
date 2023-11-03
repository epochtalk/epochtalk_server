defmodule EpochtalkServer.Repo.Migrations.PostsTsv do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :tsv, :tsvector
    end

    create index(:posts, [:tsv], using: :gin)
  end
end
