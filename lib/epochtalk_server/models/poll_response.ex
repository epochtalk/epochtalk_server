defmodule EpochtalkServer.Models.PollResponse do
  use Ecto.Schema
  import Ecto.Changeset
  # import Ecto.Query
  # alias EpochtalkServer.Repo
  # alias EpochtalkServer.Models.PollResponse
  alias EpochtalkServer.Models.PollAnswer
  alias EpochtalkServer.Models.User

  @moduledoc """
  `PollResponse` model, for performing actions relating to `Poll` answers
  """
  @type t :: %__MODULE__{
          answer_id: non_neg_integer | nil,
          user_id: non_neg_integer | nil
        }
  @derive {Jason.Encoder, only: [:answer_id, :user_id]}
  @primary_key false
  schema "poll_responses" do
    belongs_to :answer, PollAnswer
    belongs_to :user, User
  end

  ## === Changesets Functions ===

  @doc """
  Generic changeset for `PollResponse` model
  """
  @spec changeset(
          poll_response :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(poll_response, attrs \\ %{}) do
    poll_response
    |> cast(attrs, [:answer_id, :user_id])
    |> validate_required([:answer_id, :user_id])
  end

  @doc """
  Create changeset for `PollResponse` model
  """
  @spec create_changeset(
          poll_response :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def create_changeset(poll_response, attrs \\ %{}) do
    poll_response
    |> cast(attrs, [:answer_id, :user_id])
    |> validate_required([:answer_id, :user_id])
    |> foreign_key_constraint(:answer_id, name: :poll_responses_answer_id_fkey)
    |> foreign_key_constraint(:user_id, name: :poll_responses_user_id_fkey)
  end
end
