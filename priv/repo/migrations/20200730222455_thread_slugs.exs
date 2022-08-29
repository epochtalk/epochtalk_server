defmodule Epoch.Repo.Migrations.ThreadSlugs do
  use Ecto.Migration
  import Ecto.Query

  def up do
    # add slug column
    alter table(:threads) do
      add :slug, :string, size: 100
    end

    #index
    create unique_index(:threads, [:slug])

    # flush so query populating slug will work
    flush()

    # update existing threads, set slug = id
    from(t in "threads",
      update: [set: [slug: t.id]],
      where: true)
    |> Epoch.Repo.update_all([])

    # modify threads after slug update, don't allow null
    alter table(:threads) do
      modify :slug, :string, size: 100, null: false
    end
  end

  def down do
    alter table(:threads) do
      remove :slug
    end
  end
end