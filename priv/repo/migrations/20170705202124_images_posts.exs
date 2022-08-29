defmodule Epoch.Repo.Migrations.ImagesPosts do
  use Ecto.Migration

  def change do
    create table(:images_posts) do
      add :post_id, references(:posts, [on_delete: :nilify_all])
      add :image_url, :string, null: false
    end
    create index(:images_posts, [:post_id])
    create index(:images_posts, [:image_url])
  end
end
