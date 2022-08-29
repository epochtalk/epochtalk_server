defmodule Epoch.Repo.Migrations.AdsAnalytics do
  use Ecto.Migration
  @schema_prefix "ads"

  def change do
    create table(:analytics, [prefix: @schema_prefix, primary_key: false]) do
      add :ad_id, :bigserial, primary_key: true
      add :total_impressions, :integer, default: 0, null: false
      add :total_authed_impressions, :integer, default: 0, null: false
      add :total_unique_ip_impressions, :integer, default: 0, null: false
      add :total_unique_authed_users_impressions, :integer, default: 0, null: false
    end
    
    execute """
    ALTER TABLE ONLY #{@schema_prefix}.analytics
    ADD CONSTRAINT analytics_ad_id_fkey
    FOREIGN KEY (ad_id)
    REFERENCES public.ads(id)
    ON DELETE CASCADE;
    """
  end
end
