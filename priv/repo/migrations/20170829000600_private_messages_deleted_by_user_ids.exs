defmodule Epoch.Repo.Migrations.PrivateMessagesDeletedByUserIds do
  use Ecto.Migration

  def change do
    alter table(:private_conversations) do
      add :deleted_by_user_ids, {:array, :bigint}
    end
    alter table(:private_messages) do
      add :deleted_by_user_ids, {:array, :bigint}
      remove :copied_ids
    end
  end
end