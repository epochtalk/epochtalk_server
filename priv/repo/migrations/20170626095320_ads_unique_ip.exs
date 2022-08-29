defmodule Epoch.Repo.Migrations.AdsUniqueIp do
  use Ecto.Migration
  @schema_prefix "ads"

  def change do
    create table(:unique_ip, [prefix: @schema_prefix, primary_key: false]) do
      add :ad_id, :bigint, null: false
      add :unique_ip, :string, null: false
    end

    create index(:unique_ip, [:ad_id], prefix: @schema_prefix)
    create unique_index(:unique_ip, [:ad_id, :unique_ip], prefix: @schema_prefix)

    execute """
    ALTER TABLE ONLY #{@schema_prefix}.unique_ip
    ADD CONSTRAINT unique_ip_ad_id_fkey
    FOREIGN KEY (ad_id)
    REFERENCES public.ads(id) ON DELETE CASCADE;
    """
    execute("
    CREATE FUNCTION update_unique_ip_score_on_ad() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
      BEGIN
        -- increment total_unique_ip_impressions
        UPDATE ads.analytics SET total_unique_ip_impressions = total_unique_ip_impressions + 1 WHERE ad_id = NEW.ad_id;

        RETURN NEW;
      END;
    $$;
    ")

    execute """
    CREATE TRIGGER update_unique_ip_score_on_ad_trigger
    AFTER INSERT ON #{@schema_prefix}.unique_ip
    FOR EACH ROW EXECUTE PROCEDURE public.update_unique_ip_score_on_ad();
    """
  end
end
