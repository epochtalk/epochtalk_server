defmodule Epoch.Repo.Migrations.ModSchema do
  use Ecto.Migration
  @schema_prefix "mod"

  def change do
    create table(:notes, [prefix: @schema_prefix]) do
      add :moderator_id, :bigint
      add :subject, :string
      add :body, :text, default: ""
      add :created_at, :timestamp
      add :imported_at, :timestamp
      add :updated_at, :timestamp
    end

    execute """
    ALTER TABLE ONLY #{@schema_prefix}.notes
    ADD CONSTRAINT notes_moderator_id_fkey
    FOREIGN KEY (moderator_id)
    REFERENCES public.users(id);
    """

    create table(:reports, [prefix: @schema_prefix]) do
      add :user_id, :bigint
      add :thread_id, :bigint
      add :post_id, :bigint
      add :reason_subject, :string
      add :reason_body, :text, default: ""
      add :created_at, :timestamp
      add :imported_at, :timestamp
      add :updated_at, :timestamp
    end

    execute """
    ALTER TABLE ONLY #{@schema_prefix}.reports
    ADD CONSTRAINT reports_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES public.users(id);
    """

    execute """
    ALTER TABLE ONLY #{@schema_prefix}.reports
    ADD CONSTRAINT reports_thread_id_fkey
    FOREIGN KEY (thread_id)
    REFERENCES public.threads(id);
    """

    execute """
    ALTER TABLE ONLY #{@schema_prefix}.reports
    ADD CONSTRAINT reports_post_id_fkey
    FOREIGN KEY (post_id)
    REFERENCES public.posts(id);
    """
  end
end
