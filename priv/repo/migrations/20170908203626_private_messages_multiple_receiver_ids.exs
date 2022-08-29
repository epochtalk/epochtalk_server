defmodule Epoch.Repo.Migrations.PrivateMessagesMultipleReceiverIds do
  use Ecto.Migration

  def change do

    alter table(:private_messages) do
      remove :receiver_id
      add :receiver_ids, {:array, :bigint}, default: []
    end

    # create index(:private_messages, [:receiver_ids], name: :private_messages_receiver_ids_gin, using: "GIN")

  end
end