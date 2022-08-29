defmodule Epoch.Repo.Migrations.UsersSchema do
  use Ecto.Migration
  @schema_prefix "users"

  def change do
    create table(:bans, [prefix: @schema_prefix]) do
      add :user_id, :bigint, null: false
      add :expiration, :timestamp, null: false
      add :created_at, :timestamp
      add :updated_at, :timestamp
    end

    create unique_index(:bans, [:user_id], prefix: @schema_prefix)
    execute("ALTER TABLE ONLY users.bans ADD CONSTRAINT bans_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)")

    create table(:board_bans, [prefix: @schema_prefix, primary_key: false]) do
      add :user_id, :bigint, null: false
      add :board_id, :bigint, null: false
    end

    create index(:board_bans, [:board_id], prefix: @schema_prefix)
    create index(:board_bans, [:user_id], prefix: @schema_prefix)
    create unique_index(:board_bans, [:board_id, :user_id], prefix: @schema_prefix)

    execute("ALTER TABLE ONLY users.board_bans ADD CONSTRAINT board_bans_board_id_fkey FOREIGN KEY (board_id) REFERENCES public.boards(id) ON DELETE CASCADE")
    execute("ALTER TABLE ONLY users.board_bans ADD CONSTRAINT board_bans_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE")

    create table(:ignored, [prefix: @schema_prefix, primary_key: false]) do
      add :user_id, :bigint, null: false
      add :ignored_user_id, :bigint, null: false
      add :created_at, :timestamp
    end

    create index(:ignored, [:user_id], prefix: @schema_prefix)
    create index(:ignored, [:ignored_user_id], prefix: @schema_prefix)
    create unique_index(:ignored, [:user_id, :ignored_user_id], prefix: @schema_prefix)

    create table(:ips, [prefix: @schema_prefix, primary_key: false]) do
      add :user_id, :bigint, null: false
      add :user_ip, :string, null: false
      add :created_at, :timestamp
    end

    create index(:ips, [:created_at], prefix: @schema_prefix)
    create index(:ips, [:user_id], prefix: @schema_prefix)
    create index(:ips, [:user_ip], prefix: @schema_prefix)
    create unique_index(:ips, [:user_id, :user_ip], prefix: @schema_prefix)

    create table(:preferences, [prefix: @schema_prefix, primary_key: false]) do
      add :user_id, :bigint, null: false
      add :posts_per_page, :integer, default: 25
      add :threads_per_page, :integer, default: 25
      add :collapsed_categories, :jsonb, default: fragment("'{\"cats\": []}'::jsonb")
    end

    create index(:preferences, [:user_id], prefix: @schema_prefix)
    execute("ALTER TABLE ONLY users.preferences ADD CONSTRAINT preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)")

    create table(:profiles, [prefix: @schema_prefix]) do
      add :user_id, :bigint
      add :avatar, :string, default: ""
      add :position, :string
      add :signature, :text
      add :post_count, :integer, default: 0
      add :fields, :jsonb
      add :raw_signature, :text
      add :last_active, :timestamp
    end

    create unique_index(:profiles, [:user_id], prefix: @schema_prefix)
    create index(:profiles, ["last_active DESC"], prefix: @schema_prefix)

    execute("ALTER TABLE ONLY users.profiles ADD CONSTRAINT profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE")

    create table(:thread_views, [prefix: @schema_prefix, primary_key: false]) do
      add :user_id, :bigint
      add :thread_id, :bigint
      add :time, :timestamp
    end

    execute("ALTER TABLE ONLY users.thread_views ADD CONSTRAINT thread_views_thread_id_fkey FOREIGN KEY (thread_id) REFERENCES public.threads(id) ON UPDATE CASCADE ON DELETE CASCADE")
    execute("ALTER TABLE ONLY users.thread_views ADD CONSTRAINT thread_views_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE")


    create index(:thread_views, [:user_id], prefix: @schema_prefix)
    create unique_index(:thread_views, [:user_id, :thread_id], prefix: @schema_prefix)

    create table(:watch_boards, [prefix: @schema_prefix, primary_key: false]) do
      add :user_id, :bigint
      add :board_id, :bigint
    end

    create index(:watch_boards, [:board_id], prefix: @schema_prefix)
    create index(:watch_boards, [:user_id], prefix: @schema_prefix)
    create unique_index(:watch_boards, [:user_id, :board_id], prefix: @schema_prefix)

    execute("ALTER TABLE ONLY users.watch_boards ADD CONSTRAINT watch_boards_board_id_fkey FOREIGN KEY (board_id) REFERENCES public.boards(id) ON DELETE CASCADE")
    execute("ALTER TABLE ONLY users.watch_boards ADD CONSTRAINT watch_boards_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE")

    create table(:watch_threads, [prefix: @schema_prefix, primary_key: false]) do
      add :user_id, :bigint
      add :thread_id, :bigint
    end

    create index(:watch_threads, [:thread_id], prefix: @schema_prefix)
    create index(:watch_threads, [:user_id], prefix: @schema_prefix)
    create unique_index(:watch_threads, [:user_id, :thread_id], prefix: @schema_prefix)

    execute("ALTER TABLE ONLY users.watch_threads ADD CONSTRAINT watch_threads_thread_id_fkey FOREIGN KEY (thread_id) REFERENCES public.threads(id) ON DELETE CASCADE")
    execute("ALTER TABLE ONLY users.watch_threads ADD CONSTRAINT watch_threads_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE")
  end
end
