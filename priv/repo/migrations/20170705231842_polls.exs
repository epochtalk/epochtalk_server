defmodule Epoch.Repo.Migrations.Polls do
  use Ecto.Migration

  def change do
    create table(:polls) do
      add :thread_id, references(:threads), null: false
      add :question, :text, null: false
      add :locked , :boolean, default: false
      add :max_answers, :integer, default: 1, null: false
      add :expiration, :timestamp
      add :change_vote, :boolean, default: false, null: false
      # display_mode polls_display_enum DEFAULT 'always'::polls_display_enum NOT NULL
      add :display_mode, :polls_display_enum, default: fragment("'always'::polls_display_enum"), null: false
    end

    create unique_index(:polls, [:thread_id])

    create table(:poll_answers) do
      add :poll_id, references(:polls, on_delete: :delete_all), null: false
      add :answer, :text, null: false
    end

    create table(:poll_responses, primary_key: false) do
      add :answer_id, references(:poll_answers, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end
  end
end
