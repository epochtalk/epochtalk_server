defmodule EpochtalkServer.Models.Post do
  use Ecto.Schema
  import Ecto.Changeset
  # alias EpochtalkServer.Repo
  # alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.User

  @moduledoc """
  `Post` model, for performing actions relating to forum posts
  """
  @type t :: %__MODULE__{
          id: non_neg_integer | nil,
          thread_id: non_neg_integer | nil,
          user_id: non_neg_integer | nil,
          locked: boolean | nil,
          deleted: boolean | nil,
          position: non_neg_integer | nil,
          content: map() | nil,
          metadata: map() | nil,
          created_at: NaiveDateTime.t() | nil,
          imported_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }
  schema "posts" do
    belongs_to :thread, Thread
    belongs_to :user, User
    field :locked, :boolean
    field :deleted, :boolean
    field :position, :integer
    field :content, :map
    field :metadata, :map
    field :created_at, :naive_datetime
    field :updated_at, :naive_datetime
    field :imported_at, :naive_datetime
    # field :smf_message, :map, virtual: true
  end

  ## === Changesets Functions ===

  @doc """
  Create generic changeset for `Post` model
  """
  @spec changeset(post :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def changeset(post, attrs) do
    post
    |> cast(attrs, [
      :id,
      :thread_id,
      :user_id,
      :locked,
      :deleted,
      :position,
      :content,
      :metadata,
      :imported_at,
      :created_at,
      :updated_at
    ])
    |> unique_constraint(:id, name: :posts_pkey)
    |> foreign_key_constraint(:thread_id, name: :posts_thread_id_fkey)
  end

  @doc """
  Create changeset for `Post` model
  """
  @spec create_changeset(post :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def create_changeset(post, attrs) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    attrs =
      attrs
      |> Map.put("created_at", now)
      |> Map.put("updated_at", now)

    post
    |> cast(attrs, [
      :thread_id,
      :user_id,
      :locked,
      :deleted,
      :content,
      :created_at,
      :updated_at
    ])
    |> unique_constraint(:id, name: :posts_pkey)
    |> foreign_key_constraint(:thread_id, name: :posts_thread_id_fkey)
  end

  @doc """
  Sets the `post_position` of a new `Post`, by querying the `post_count` of the
  parent `Thread` and adding one
  """
  @spec set_position_using_thread(id :: non_neg_integer, thread_id :: non_neg_integer) :: {non_neg_integer(), nil}
  def set_position_using_thread(id, thread_id) do
    thread_post_count_query = from t in Thread,
      select: t.post_count,
      where: t.id == ^thread_id

    thread_post_count = Repo.one(thread_post_count_query)

    from(p in Post, where: p.id == ^id)
    |> Repo.update_all(set: [position: thread_post_count + 1])
  end
end
