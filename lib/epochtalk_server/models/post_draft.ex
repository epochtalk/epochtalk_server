defmodule EpochtalkServer.Models.PostDraft do
  use Ecto.Schema
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.PostDraft

  @moduledoc """
  `PostDraft` model, for performing actions relating to a `User`'s `Post` draft
  """
  @type t :: %__MODULE__{
          user_id: non_neg_integer | nil,
          draft: String.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }
  @derive {Jason.Encoder,
           only: [
             :user_id,
             :draft,
             :updated_at
           ]}
  @schema_prefix "posts"
  @primary_key false
  schema "user_drafts" do
    belongs_to :user, User
    field :draft, :string
    field :updated_at, :naive_datetime
  end

  ## === Database Functions ===

  @doc """
  Returns `PostDraft` Data given a `User` id
  """
  @spec by_user_id(user_id :: integer) :: t() | nil
  def by_user_id(user_id) do
    query =
      from p in PostDraft,
        where: p.user_id == ^user_id

    Repo.one(query)
  end

  @doc """
  Used to upsert a `PostDraft` for a specific `User`
  """
  @spec upsert(user_id :: non_neg_integer, draft :: String.t()) ::
          {:ok, t()} | {:error, Ecto.Changeset.t()}
  def upsert(user_id, draft) when is_integer(user_id) and is_binary(draft) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    Repo.insert(
      %PostDraft{user_id: user_id, draft: draft, updated_at: now},
      on_conflict: [set: [draft: draft, updated_at: now]],
      conflict_target: [:user_id]
    )
  end

end
