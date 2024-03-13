defmodule EpochtalkServer.Models.PollAnswer do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.PollAnswer
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
  @derive {Jason.Encoder, only: [:id, :answer, :votes]}
  schema "poll_answers" do
    belongs_to :poll, Poll
    field :answer, :string
    field :votes, :integer, virtual: true, default: 0
    has_many :poll_responses, PollResponse, foreign_key: :answer_id
  end

  ## === Changesets Functions ===

  @doc """
  Generic changeset for `PollAnswer` model
  """
  @spec changeset(
          poll_answer :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(poll_answer, attrs \\ %{}) do
    poll_answer
    |> cast(attrs, [:id, :poll_id, :answer])
    |> validate_required([:poll_id, :answer])
  end

  @doc """
  Create changeset for `PollAnswer` model
  """
  @spec create_changeset(
          poll_answer :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def create_changeset(poll_answer, attrs \\ %{}) do
    poll_answer
    |> cast(attrs, [:poll_id, :answer])
    |> validate_required([:poll_id, :answer])
    |> validate_length(:answer, min: 1, max: 255)
    |> unique_constraint(:id, name: :poll_answers_pkey)
    |> foreign_key_constraint(:poll_id, name: :poll_answers_poll_id_fkey)
  end

  @doc """
  Creates a new `PollAnswer` in the database
  """
  @spec create(post_attrs :: map()) :: {:ok, post :: t()} | {:error, Ecto.Changeset.t()}
  def create(poll_answer_attrs) do
    post_cs = create_changeset(%PollAnswer{}, poll_answer_attrs)
    Repo.insert(post_cs)
  end
end
