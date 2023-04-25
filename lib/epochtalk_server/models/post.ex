defmodule EpochtalkServer.Models.Post do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Profile

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
  @derive {Jason.Encoder,
           only: [
             :id,
             :thread_id,
             :thread,
             :user_id,
             :locked,
             :deleted,
             :position,
             :content,
             :metadata,
             :created_at,
             :updated_at,
             :imported_at
           ]}
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

    # set default values and timestamps
    post =
      post
      |> Map.put(:deleted, false)
      |> Map.put(:locked, false)
      |> Map.put(:created_at, now)
      |> Map.put(:updated_at, now)

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
    |> validate_required([:user_id, :thread_id, :content])
    |> validate_change(:content, fn _, content ->
      has_key = fn key ->
        case String.trim(content[key] || "") do
          "" -> [{key, "can't be blank"}]
          _ -> []
        end
      end

      # validate content map has :title and :body, and they're not blank
      has_key.(:title) ++ has_key.(:body)
    end)
    |> unique_constraint(:id, name: :posts_pkey)
    |> foreign_key_constraint(:thread_id, name: :posts_thread_id_fkey)
  end

  ## === Database Functions ===

  @doc """
  Creates a new `Post` in the database
  """
  @spec create(post_attrs :: map()) :: {:ok, post :: t()} | {:error, Ecto.Changeset.t()}
  def create(post) do
    Repo.transaction(fn ->
      post_cs = create_changeset(%Post{}, post)

      case Repo.insert(post_cs) do
        # changeset valid, insert success, update metadata threads and return thread
        {:ok, db_post} ->
          # Increment user post count
          Profile.increment_post_count(db_post.user_id)

          # Set thread created_at and updated_at
          Thread.set_timestamps(db_post.thread_id)

          # Set post position
          Post.set_position_using_thread(db_post.id, db_post.thread_id)

          # Increment thread post ocunt
          Thread.increment_post_count(db_post.thread_id)

          # Requery post with position and thread slug info
          Repo.one(from p in Post, where: p.id == ^db_post.id, preload: [:thread])

        # changeset error
        {:error, cs} ->
          Repo.rollback(cs)
      end
    end)
  end

  @doc """
  Sets the `post_position` of a new `Post`, by querying the `post_count` of the
  parent `Thread` and adding one
  """
  @spec set_position_using_thread(id :: non_neg_integer, thread_id :: non_neg_integer) ::
          {non_neg_integer(), nil}
  def set_position_using_thread(id, thread_id) do
    thread_post_count_query =
      from t in Thread,
        select: t.post_count,
        where: t.id == ^thread_id

    thread_post_count = Repo.one(thread_post_count_query)

    from(p in Post, where: p.id == ^id)
    |> Repo.update_all(set: [position: thread_post_count + 1])
  end
end
