defmodule EpochtalkServer.Repo.Migrations.PostsTsvTrigger do
  use Ecto.Migration

  def up do
    execute """
      --
      -- Name: search_index_post(); Type: FUNCTION; Schema: public; Owner: -
      --

      CREATE FUNCTION public.search_index_post() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
        BEGIN
          UPDATE posts SET
              tsv = x.tsv
          FROM (
              SELECT id,
                    setweight(to_tsvector('simple', COALESCE(content ->> 'title','')), 'A') ||
                    setweight(to_tsvector('simple', COALESCE(content ->> 'body','')), 'B')
                    AS tsv
              FROM posts WHERE id = NEW.id
          ) AS x
          WHERE x.id = posts.id;

          RETURN NEW;
        END;
      $$;
    """

    execute """
      CREATE TRIGGER search_index_post AFTER INSERT ON public.posts FOR EACH ROW EXECUTE PROCEDURE public.search_index_post();
    """
  end
end
