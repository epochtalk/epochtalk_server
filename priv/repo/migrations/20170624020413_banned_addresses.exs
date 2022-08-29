defmodule Epoch.Repo.Migrations.BannedAddresses do
  use Ecto.Migration

  def change do
    create table(:banned_addresses, primary_key: false) do
      add :hostname, :string, size: 255
      add :ip1, :integer
      add :ip2, :integer
      add :ip3, :integer
      add :ip4, :integer
      add :weight, :numeric, null: false
      add :decay, :boolean, null: false
      add :created_at, :timestamp
      add :imported_at, :timestamp
      add :updates, {:array, :timestamp}, default: []

      # updates timestamp with time zone[] DEFAULT ARRAY[]::timestamp with time zone[],
      # imported_at timestamp with time zone,
      # CONSTRAINT banned_addresses_hostname_or_ip_contraint CHECK ((((ip1 IS NOT NULL) AND (ip2 IS NOT NULL) AND (ip3 IS NOT NULL) AND (ip4 IS NOT NULL) AND (hostname IS NULL)) OR ((hostname IS NOT NULL) AND (ip1 IS NULL) AND (ip2 IS NULL) AND (ip3 IS NULL) AND (ip4 IS NULL))))

    end
    execute "ALTER TABLE banned_addresses ADD CONSTRAINT banned_addresses_hostname_or_ip_contraint CHECK ((((ip1 IS NOT NULL) AND (ip2 IS NOT NULL) AND (ip3 IS NOT NULL) AND (ip4 IS NOT NULL) AND (hostname IS NULL)) OR ((hostname IS NOT NULL) AND (ip1 IS NULL) AND (ip2 IS NULL) AND (ip3 IS NULL) AND (ip4 IS NULL))))"

    create index(:banned_addresses, :created_at)
    create index(:banned_addresses, :decay)
    create unique_index(:banned_addresses, [:hostname])
    create index(:banned_addresses, :imported_at)
    create index(:banned_addresses, :weight)

    execute "ALTER TABLE ONLY banned_addresses ADD CONSTRAINT banned_addresses_unique_ip_contraint UNIQUE (ip1, ip2, ip3, ip4)"
  end
end
