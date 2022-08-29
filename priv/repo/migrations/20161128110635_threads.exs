defmodule Epoch.Repo.Migrations.Threads do
  use Ecto.Migration

  def change do
    create table(:threads) do
      add :board_id, references(:boards, on_update: :update_all, on_delete: :delete_all)
      add :locked, :boolean
      add :sticky, :boolean
      add :moderated, :boolean
      add :post_count, :integer, default: 0
      add :created_at, :timestamp
      add :imported_at, :timestamp
      add :updated_at, :timestamp
    end

    create index(:threads, [:board_id, "updated_at DESC"])
    create index(:threads, [:board_id], where: "sticky = true")
    create index(:threads, [:updated_at])

    execute """
    CREATE FUNCTION create_thread() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
      BEGIN
        -- increment metadata.boards' thread_count
        UPDATE boards SET thread_count = thread_count + 1 WHERE id = NEW.board_id;

        RETURN NEW;
      END;
    $$;
    """

    execute """
    CREATE TRIGGER create_thread_trigger
    AFTER INSERT ON threads
    FOR EACH ROW EXECUTE PROCEDURE create_thread();
    """

    execute """
    CREATE FUNCTION delete_thread() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
      BEGIN
        -- decrement metadata.boards' thread_count and post_count
        UPDATE boards SET post_count = post_count - OLD.post_count WHERE id = OLD.board_id;

        -- decrement metadata.boards' thread_count
        UPDATE boards SET thread_count = thread_count - 1 WHERE id = OLD.board_id;

        -- update metadata.boards' last post information
        UPDATE metadata.boards
        SET last_post_username = username,
            last_post_created_at = created_at,
            last_thread_id = thread_id,
            last_thread_title = title,
            last_post_position = position
        FROM (
          SELECT pLast.username as username,
                pLast.created_at as created_at,
                t.id as thread_id,
                pFirst.title as title,
                pLast.position as position
          FROM (
            SELECT id
            FROM threads
            WHERE board_id = OLD.board_id
            ORDER BY updated_at DESC LIMIT 1
          ) t LEFT JOIN LATERAL (
            SELECT p.content ->> 'title' as title
            FROM posts p
            WHERE p.thread_id = t.id
            ORDER BY p.created_at LIMIT 1
          ) pFirst ON true LEFT JOIN LATERAL (
            SELECT u.username, p.position, p.created_at
            FROM posts p LEFT JOIN users u ON u.id = p.user_id
            WHERE p.thread_id = t.id
            ORDER BY p.created_at DESC LIMIT 1
          ) pLast ON true
        ) AS subquery
        WHERE board_id = OLD.board_id;

        RETURN OLD;
      END;
    $$;
    """

    execute """
    CREATE TRIGGER delete_thread_trigger
    AFTER DELETE ON threads
    FOR EACH ROW EXECUTE PROCEDURE delete_thread()
    """

    execute """
    CREATE FUNCTION update_thread() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
      BEGIN
        -- update metadta.board' post_count
        IF OLD.post_count < NEW.post_count THEN
          UPDATE boards SET post_count = post_count + 1 WHERE id = OLD.board_id;
        ELSE
          UPDATE boards SET post_count = post_count - 1 WHERE id = OLD.board_id;
        END IF;

        -- update metadata.boards' last post information
        UPDATE metadata.boards
        SET last_post_username = username,
            last_post_created_at = created_at,
            last_thread_id = thread_id,
            last_thread_title = title,
            last_post_position = position
        FROM (
          SELECT pLast.username as username,
                pLast.created_at as created_at,
                t.id as thread_id,
                pFirst.title as title,
                pLast.position as position
          FROM (
            SELECT id
            FROM threads
            WHERE board_id = OLD.board_id
            ORDER BY updated_at DESC LIMIT 1
          ) t LEFT JOIN LATERAL (
            SELECT p.content ->> 'title' as title
            FROM posts p
            WHERE p.thread_id = t.id
            ORDER BY p.created_at LIMIT 1
          ) pFirst ON true LEFT JOIN LATERAL (
            SELECT u.username, p.position, p.created_at
            FROM posts p LEFT JOIN users u ON u.id = p.user_id
            WHERE p.thread_id = t.id
            ORDER BY p.created_at DESC LIMIT 1
          ) pLast ON true
        ) AS subquery
        WHERE board_id = OLD.board_id;

        RETURN NEW;
      END;
    $$;
    """

    execute """
    CREATE TRIGGER update_thread_trigger
    AFTER UPDATE OF post_count
    ON threads FOR EACH ROW EXECUTE PROCEDURE update_thread()
    """
  end
end
