defmodule EpochtalkServer.Repo.Migrations.ImageReferences do
  use Ecto.Migration
  @schema_prefix "image_references"

  def up do
    # drop image expirations table
    drop table(:image_expirations)
    # drop images posts table
    drop table(:images_posts)

    # create image_references table
    create table(:image_references) do
      add :uuid, :string
      add :url, :string
      add :length, :integer
      add :type, :string
      add :checksum, :string
      add :expiration, :timestamp
      add :created_at, :timestamp
    end

    execute "CREATE SCHEMA #{@schema_prefix}"

    # create schema for joining through posts, messages, profiles
    create table(:posts, prefix: @schema_prefix) do
      add :post_id, :bigint
      add :image_reference_id, :bigint
    end
    create unique_index(:posts, [:post_id, :image_reference_id], prefix: @schema_prefix)

    create table(:messages, prefix: @schema_prefix) do
      add :message_id, :bigint
      add :image_reference_id, :bigint
    end
    create unique_index(:messages, [:message_id, :image_reference_id], prefix: @schema_prefix)

    create table(:profiles, prefix: @schema_prefix) do
      add :profile_id, :bigint
      add :image_reference_id, :bigint
    end
    create unique_index(:profiles, [:profile_id, :image_reference_id], prefix: @schema_prefix)
  end
  def down do
    # drop image references table and join tables
    drop table(:image_references)
    drop table(:posts, prefix: @schema_prefix)
    drop table(:messages, prefix: @schema_prefix)
    drop table(:profiles, prefix: @schema_prefix)

    # re-create image expirations table
    create table(:image_expirations, primary_key: false) do
      add :expiration, :timestamp
      add :image_url, :string, size: 2000, null: false
    end

    create index(:image_expirations, [:expiration])
    create index(:image_expirations, [:image_url])

    # re-create images posts table
    create table(:images_posts) do
      add :post_id, references(:posts, on_delete: :nilify_all)
      add :image_url, :string, null: false
    end

    create index(:images_posts, [:post_id])
    create index(:images_posts, [:image_url])
  end
end
