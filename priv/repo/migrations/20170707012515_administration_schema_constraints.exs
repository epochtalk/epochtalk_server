defmodule Epoch.Repo.Migrations.AdministrationSchemaConstraints do
  use Ecto.Migration

  @schema_prefix "administration"

  def change do
    execute("ALTER TABLE ONLY #{@schema_prefix}.reports_messages ADD CONSTRAINT offender_message_id_fkey FOREIGN KEY (offender_message_id) REFERENCES public.private_messages(id) ON DELETE CASCADE")
    execute("ALTER TABLE ONLY #{@schema_prefix}.reports_messages ADD CONSTRAINT reporter_user_id_fkey FOREIGN KEY (reporter_user_id) REFERENCES public.users(id) ON DELETE SET NULL")
    execute("ALTER TABLE ONLY #{@schema_prefix}.reports_messages ADD CONSTRAINT reviewer_user_id_fkey FOREIGN KEY (reviewer_user_id) REFERENCES public.users(id) ON DELETE SET NULL")

    execute("ALTER TABLE ONLY #{@schema_prefix}.reports_messages_notes ADD CONSTRAINT report_id_fkey FOREIGN KEY (report_id) REFERENCES #{@schema_prefix}.reports_messages(id) ON DELETE CASCADE")
    execute("ALTER TABLE ONLY #{@schema_prefix}.reports_messages_notes ADD CONSTRAINT user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL")
  end
end
