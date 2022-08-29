defmodule :"Elixir.Epoch.Repo.Migrations.Polls-fk-fix" do
  use Ecto.Migration

  def up do
    drop(constraint(:polls, "polls_thread_id_fkey"))

    alter table(:polls) do
      modify :thread_id, references(:threads, on_delete: :delete_all)
    end
  end

  def down do
    drop(constraint(:polls, "polls_thread_id_fkey"))

    alter table(:polls) do
      modify :thread_id, references(:threads, on_delete: :nothing)
    end
  end
end