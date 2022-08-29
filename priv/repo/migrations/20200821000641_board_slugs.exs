defmodule Epoch.Repo.Migrations.BoardSlugs do
  use Ecto.Migration
  import Ecto.Query

  def up do
    # add slug column
    alter table(:boards) do
      add :slug, :string, size: 100
    end

    #index
    create unique_index(:boards, [:slug])

    # flush so query populating slug will work
    flush()

    # update existing boards, set slug = id
    from(b in "boards",
      update: [set: [slug: b.id]],
      where: true)
    |> Epoch.Repo.update_all([])

    # modify boards after slug update, don't allow null
    alter table(:boards) do
      modify :slug, :string, size: 100, null: false
    end
  end

  def down do
    alter table(:boards) do
      remove :slug
    end
  end
end