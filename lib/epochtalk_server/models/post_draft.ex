defmodule EpochtalkServer.Models.PostDraft do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
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

  ## === Changeset Functions ===

  @doc """
  Create a changeset for upserting a `PostDraft`
  """
  @spec upsert_changeset(draft :: PostDraft.t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def upsert_changeset(draft, attrs \\ %{}) do
    updated_at = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    draft =
      draft
      |> Map.put(:updated_at, updated_at)

    draft
    |> cast(attrs, [:user_id, :draft, :updated_at])
    |> validate_required([:user_id, :updated_at])
    |> validate_length(:draft, min: 1, max: 64_000)
    |> unique_constraint(:user_id, name: :user_drafts_user_id_index)
    |> foreign_key_constraint(:user_id, name: :user_drafts_user_id_fkey)
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
  @spec upsert(user_id :: non_neg_integer, attrs :: map()) ::
          {:ok, t()} | {:error, Ecto.Changeset.t()}
  def upsert(user_id, attrs) when is_integer(user_id) do
    post_draft_cs = upsert_changeset(%PostDraft{user_id: user_id}, attrs)

    Repo.insert(
      post_draft_cs,
      on_conflict: [
        set: [
          draft: Map.get(post_draft_cs.changes, :draft),
          updated_at: Map.get(post_draft_cs.data, :updated_at)
        ]
      ],
      conflict_target: [:user_id]
    )
  end
end
