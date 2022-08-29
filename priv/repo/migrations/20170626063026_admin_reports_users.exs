defmodule Epoch.Repo.Migrations.AdminReportsUsers do
  use Ecto.Migration
  @schema_prefix "administration"

  def change do
    create table(:reports_users, [prefix: @schema_prefix]) do
      add :status, :report_status_type, default: fragment("'Pending'::report_status_type"), null: false
      add :reporter_user_id, :bigint
      add :reporter_reason, :text, default: "", null: false
      add :reviewer_user_id, :bigint
      add :offender_user_id, :bigint, null: false
      add :created_at, :timestamp
      add :updated_at, :timestamp
    end
    create index(:reports_users, [:created_at], prefix: @schema_prefix)

    execute """
    ALTER TABLE ONLY #{@schema_prefix}.reports_users
    ADD CONSTRAINT reporter_user_id_fkey
    FOREIGN KEY (reporter_user_id)
    REFERENCES public.users(id)
    ON DELETE SET NULL;
    """

    execute """
    ALTER TABLE ONLY #{@schema_prefix}.reports_users
    ADD CONSTRAINT reviewer_user_id_fkey
    FOREIGN KEY (reviewer_user_id)
    REFERENCES public.users(id)
    ON DELETE SET NULL;
    """

    execute """
    ALTER TABLE ONLY #{@schema_prefix}.reports_users
    ADD CONSTRAINT offender_user_id_fkey
    FOREIGN KEY (offender_user_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE;
    """
  end
end
