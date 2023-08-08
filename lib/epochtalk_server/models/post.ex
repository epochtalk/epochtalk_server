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
  Creates a new `Post` in the database, used during `Thread` creation
  """
  @spec create(post_attrs :: map()) :: {:ok, post :: t()} | {:error, Ecto.Changeset.t()}
  def create(post_attrs) do
    Repo.transaction(fn ->
      post_cs = create_changeset(%Post{}, post_attrs)

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
  Creates a new `Post` in the database
  """
  @spec create(post_attrs :: map(), user_id :: non_neg_integer) ::
          {:ok, post :: t()} | {:error, Ecto.Changeset.t()}
  def create(post_attrs, user_id),
    do:
      create(%{
        "thread_id" => post_attrs["thread_id"],
        "user_id" => user_id,
        "content" => %{title: post_attrs["title"], body: post_attrs["body"]}
      })

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

  @doc """
  Paginates `Post` records for a given a `Thread`
  """
  @spec page_by_thread_id(
          thread_id :: non_neg_integer,
          page :: non_neg_integer | nil,
          opts :: list() | nil
        ) :: [map()] | []
  def page_by_thread_id(thread_id, page \\ 1, opts \\ []) do
    per_page = Keyword.get(opts, :per_page, 25)
    user_id = Keyword.get(opts, :user_id)
    page = if start = Keyword.get(opts, :start), do: ceil(start / per_page), else: page
    start = page * per_page - per_page
    start = if start < 0, do: 0, else: start

    inner_query =
      Post
      |> where([p], p.thread_id == ^thread_id and p.position > ^start)
      |> order_by([p], p.position)
      |> limit(^per_page)
      |> select([p], %{id: p.id, position: p.position})

    from(plist in subquery(inner_query))
    |> join(
      :left_lateral,
      [plist],
      p1 in fragment(
        """
          SELECT
            p.thread_id, t.board_id, t.slug, b.right_to_left, p.user_id, p.content ->> \'title\' as title,
            p.content ->> \'body\' as body, p.metadata, p.deleted, p.locked, p.created_at,
            p.updated_at, p.imported_at, CASE WHEN EXISTS (
              SELECT rp.id
              FROM administration.reports_posts rp
              WHERE rp.offender_post_id = p.id AND rp.reporter_user_id = ?
            )
            THEN \'TRUE\'::boolean ELSE \'FALSE\'::boolean END AS reported,
            CASE WHEN EXISTS (
              SELECT ru.id
              FROM administration.reports_users ru
              WHERE ru.offender_user_id = p.user_id AND ru.reporter_user_id = ? AND ru.status = \'Pending\'
            )
            THEN \'TRUE\'::boolean ELSE \'FALSE\'::boolean END AS reported_author,
            CASE WHEN p.user_id = (
              SELECT user_id
              FROM posts
              WHERE thread_id = t.id ORDER BY created_at limit 1
            )
            THEN \'TRUE\'::boolean ELSE \'FALSE\'::boolean END AS original_poster,
            u.username, u.deleted as user_deleted, up.signature, up.post_count, up.avatar,
            up.fields->\'name\' as name
          FROM posts p
          LEFT JOIN users u ON p.user_id = u.id
          LEFT JOIN users.profiles up ON u.id = up.user_id
          LEFT JOIN threads t ON p.thread_id = t.id
          LEFT JOIN boards b ON t.board_id = b.id
          WHERE p.id = ?
        """,
        ^user_id,
        ^user_id,
        plist.id
      ),
      on: true
    )
    |> join(
      :left_lateral,
      [plist, p1],
      p2 in fragment(
        """
          SELECT r.priority, r.highlight_color, r.name as role_name
          FROM roles_users ru
          LEFT JOIN roles r ON ru.role_id = r.id
          WHERE ? = ru.user_id
          ORDER BY r.priority limit 1
        """,
        p1.user_id
      ),
      on: true
    )
    |> join(
      :left_lateral,
      [],
      p3 in fragment("""
        SELECT priority FROM roles WHERE lookup =\'user\'
      """),
      on: true
    )
    |> select([plist, p1, p2, p3], %{
      id: plist.id,
      position: plist.position,
      thread_id: p1.thread_id,
      board_id: p1.board_id,
      slug: p1.slug,
      user_id: p1.user_id,
      title: p1.title,
      body: p1.body,
      deleted: p1.deleted,
      locked: p1.locked,
      right_to_left: p1.right_to_left,
      metadata: p1.metadata,
      created_at: p1.created_at,
      updated_at: p1.updated_at,
      imported_at: p1.updated_at,
      username: p1.username,
      reported: p1.reported,
      reported_author: p1.reported_author,
      original_poster: p1.original_poster,
      user_deleted: p1.user_deleted,
      signature: p1.signature,
      avatar: p1.avatar,
      post_count: p1.post_count,
      name: p1.name,
      priority: p2.priority,
      highlight_color: p2.highlight_color,
      role_name: p2.role_name,
      default_priority: p3.priority
    })
    |> order_by([plist], plist.position)
    |> Repo.all()
  end

  @doc """
  Used to find a specific `Post` by it's `id`
  """
  @spec find_by_id(id :: non_neg_integer) :: t()
  def find_by_id(id) when is_integer(id) do
    query =
      from p in Post,
        where: p.id == ^id,
        preload: [:thread, user: :profile]

    Repo.one(query)
  end
end
