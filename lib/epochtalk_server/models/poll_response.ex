defmodule EpochtalkServer.Models.PollResponse do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.PollResponse
  alias EpochtalkServer.Models.PollAnswer
  alias EpochtalkServer.Models.Poll
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

  ## === Database Functions ===

  @doc """
  Create on `PollResponse` for specific `Poll`. Used to vote for a `Poll`
  """
  @spec create(attrs :: map, user_id :: integer) :: {:ok, any()} | {:error, any()}
  def create(%{"answer_ids" => answer_ids} = attrs, user_id)
      when is_map(attrs) and is_integer(user_id),
      do:
        Repo.transaction(fn ->
          Enum.map(answer_ids, &PollResponse.create(&1, user_id))
        end)

  def create(answer_id, user_id) do
    poll_response_cs =
      create_changeset(%PollResponse{}, %{answer_id: answer_id, user_id: user_id})

    case Repo.insert(poll_response_cs) do
      {:ok, poll_response} -> poll_response
      {:error, cs} -> Repo.rollback(cs)
    end
  end

  @doc """
  Delete `PollResponse` for specific `Poll` and `User`. Used to remove vote from a `Poll`
  """
  @spec delete(thread_id :: non_neg_integer, user_id :: non_neg_integer) ::
          {non_neg_integer(), nil | [t()]}
  def delete(thread_id, user_id) do
    poll_answer_ids =
      from pa in PollAnswer,
        join: p in Poll,
        on: p.thread_id == ^thread_id and pa.poll_id == p.id,
        select: pa.id

    poll_responses_by_user =
      from pr in PollResponse,
        where: pr.answer_id in subquery(poll_answer_ids) and pr.user_id == ^user_id,
        select: pr

    Repo.delete_all(poll_responses_by_user)
  end
end
