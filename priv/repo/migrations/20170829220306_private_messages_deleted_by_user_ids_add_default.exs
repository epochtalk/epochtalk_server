defmodule Epoch.Repo.Migrations.PrivateMessagesDeletedByUserIdsAddDefault do
  use Ecto.Migration

  def change do
    alter table(:private_conversations) do
      modify :deleted_by_user_ids, {:array, :bigint}, default: []
    end
    alter table(:private_messages) do
      modify :deleted_by_user_ids, {:array, :bigint}, default: []
    end
  end
end
