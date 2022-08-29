defmodule Epoch.Repo.Migrations.AddPrivateMessageSubject do
  use Ecto.Migration

  def change do
    alter table(:private_messages) do
      add :subject, :string, null: false
    end
  end
end
