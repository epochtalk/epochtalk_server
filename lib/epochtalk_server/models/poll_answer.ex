defmodule EpochtalkServer.Models.PollAnswer do
  use Ecto.Schema
  import Ecto.Changeset
  # import Ecto.Query
  # alias EpochtalkServer.Repo
  # alias EpochtalkServer.Models.PollAnswer
  alias EpochtalkServer.Models.Poll
  alias EpochtalkServer.Models.PollResponse

  @moduledoc """
  `PollAnswer` model, for performing actions relating to `Poll` answers
  """
  @type t :: %__MODULE__{
          id: non_neg_integer | nil,
          poll_id: non_neg_integer | nil,
          answer: String.t() | nil
        }
  @derive {Jason.Encoder, only: [:poll_id, :answer]}
  schema "poll_answers" do
    belongs_to :poll, Poll
    field :answer, :string
    has_many :poll_responses, PollResponse
  end

  ## === Changesets Functions ===

  @doc """
  Generic changeset for `PollAnswer` model
  """
  @spec changeset(
          poll_answers :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(poll_answers, attrs \\ %{}) do
    poll_answers
    |> cast(attrs, [:id, :poll_id, :answer])
    |> validate_required([:poll_id, :answer])
  end

  @doc """
  Create changeset for `PollAnswer` model
  """
  @spec create_changeset(
          poll_answers :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def create_changeset(poll_answers, attrs \\ %{}) do
    poll_answers
    |> cast(attrs, [:poll_id, :answer])
    |> validate_required([:poll_id, :answer])
    |> unique_constraint(:id, name: :poll_answers_pkey)
    |> foreign_key_constraint(:poll_id, name: :poll_answers_poll_id_fkey)
  end
end
