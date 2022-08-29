defmodule Epoch.Repo.Migrations.AdsAuthedUsers do
  use Ecto.Migration
  @schema_prefix "ads"

  def change do
    create table(:authed_users, [prefix: @schema_prefix, primary_key: false]) do
      add :ad_id, :bigint, null: false
      add :user_id, :bigint, null: false
    end

    create index(:authed_users, [:ad_id], prefix: @schema_prefix)
    create unique_index(:authed_users, [:ad_id, :user_id], prefix: @schema_prefix)
    
    execute """
    ALTER TABLE ONLY #{@schema_prefix}.authed_users
    ADD CONSTRAINT authed_users_ad_id_fkey
    FOREIGN KEY (ad_id)
    REFERENCES public.ads(id)
    ON DELETE CASCADE
    """

    execute """
    ALTER TABLE ONLY #{@schema_prefix}.authed_users
    ADD CONSTRAINT authed_users_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE
    """

    execute("
    CREATE FUNCTION update_unique_authed_user_score_on_ad() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
      BEGIN
        -- increment total_unique_authed_users_impressions
        UPDATE ads.analytics SET total_unique_authed_users_impressions = total_unique_authed_users_impressions + 1 WHERE ad_id = NEW.ad_id;

        RETURN NEW;
      END;
    $$;
    ")

    execute """
    CREATE TRIGGER update_unique_authed_user_score_on_ad_trigger
    AFTER INSERT ON #{@schema_prefix}.authed_users
    FOR EACH ROW EXECUTE PROCEDURE public.update_unique_authed_user_score_on_ad()
    """
  end
end
