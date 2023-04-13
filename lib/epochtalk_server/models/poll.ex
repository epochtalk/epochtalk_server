defmodule EpochtalkServer.Models.Poll do
  use Ecto.Schema
  import Ecto.Changeset
  # import Ecto.Query
  # alias EpochtalkServer.Repo
  # alias EpochtalkServer.Models.Poll
  alias EpochtalkServer.Models.Thread

  @moduledoc """
  `Poll` model, for performing actions relating to `Thread` polls
  """
  @type t :: %__MODULE__{
          id: non_neg_integer | nil,
          thread_id: non_neg_integer | nil,
          question: String.t() | nil,
          locked: boolean | nil,
          max_answers: non_neg_integer | nil,
          expiration: NaiveDateTime.t() | nil,
          change_vote: boolean | nil,
          display_mode: String.t() | nil
        }
  @derive {Jason.Encoder,
           only: [
             :thread_id,
             :question,
             :locked,
             :max_answers,
             :expiration,
             :change_vote,
             :display_mode
           ]}
  schema "polls" do
    belongs_to :thread, Thread
    field :question, :string
    field :locked, :boolean
    field :max_answers, :integer
    field :expiration, :naive_datetime
    field :change_vote, :boolean
    field :display_mode, Ecto.Enum, values: [:always, :voted, :expired]
  end

  ## === Changesets Functions ===

  @doc """
  Generic changeset for `Poll` model
  """
  @spec changeset(
          poll :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(poll, attrs \\ %{}) do
    poll
    |> cast(attrs, [
      :id,
      :thread_id,
      :question,
      :locked,
      :max_answers,
      :expiration,
      :change_vote,
      :display_mode
    ])
    |> validate_required([
      :thread_id,
      :question,
      :locked,
      :max_answers,
      :change_vote,
      :display_mode
    ])
  end
end
