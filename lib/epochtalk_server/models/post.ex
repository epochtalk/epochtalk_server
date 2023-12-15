defmodule EpochtalkServer.Models.Post do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Profile

  @edit_window_ms 1000 * 60 * 10

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
  Create changeset for `Post` model
  """
  @spec create_changeset(post :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def create_changeset(post, attrs) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    # set default values and timestamps
    post =
      post
      |> Map.put(:deleted, attrs["deleted"] || false)
      |> Map.put(:locked, attrs["locked"] || false)
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
      string_not_blank = fn key ->
        case String.trim(content[key] || "") do
          "" -> [{key, "can't be blank"}]
          _ -> []
        end
      end

      is_string = fn key ->
        case is_binary(content[key]) do
          false -> [{key, "must be a string"}]
          true -> []
        end
      end

      # check that nested values at specified keys are strings
      errors_list = is_string.(:title) ++ is_string.(:body)

      # nested values are strings, check that values aren't blank, return errors
      if errors_list == [],
        do: string_not_blank.(:title) ++ string_not_blank.(:body),
        else: errors_list
    end)
    |> unique_constraint(:id, name: :posts_pkey)
    |> foreign_key_constraint(:thread_id, name: :posts_thread_id_fkey)
  end

  @doc """
  Create update changeset for `Post` model
  """
  @spec update_changeset(post :: t(), attrs :: map(), authed_user :: map()) :: Ecto.Changeset.t()
  def update_changeset(post, attrs, authed_user) do
    # format attrs for casting
    attrs = format_update_attrs(post, attrs, authed_user)

    # cast attrs, create update changeset
    post
    |> cast(attrs, [
      :id,
      :thread_id,
      :content,
      :metadata,
      :updated_at,
      :created_at
    ])
    |> validate_required([:id, :thread_id, :content, :created_at, :updated_at])
    |> validate_change(:content, fn _, content ->
      string_not_blank = fn key ->
        case String.trim(content[key] || "") do
          "" -> [{key, "can't be blank"}]
          _ -> []
        end
      end

      is_string = fn key ->
        case is_binary(content[key]) do
          false -> [{key, "must be a string"}]
          true -> []
        end
      end

      # check that nested values at specified keys are strings
      errors_list = is_string.(:title) ++ is_string.(:body)

      # nested values are strings, check that values aren't blank, return errors
      if errors_list == [],
        do: string_not_blank.(:title) ++ string_not_blank.(:body),
        else: errors_list
    end)
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
        "content" => %{
          title: post_attrs["title"],
          body: post_attrs["body"],
          body_html: post_attrs["body_html"]
        },
        "deleted" => post_attrs["deleted"],
        "locked" => post_attrs["locked"]
      })

  @doc """
  Updates an existing `Post` in the database
  """
  @spec update(post_attrs :: map(), authed_user :: map()) ::
          {:ok, post :: t()} | {:error, Ecto.Changeset.t()} | {:error, any()}
  def update(post_attrs, authed_user) do
    Repo.transaction(fn ->
      query =
        from p in Post,
          where: p.id == ^post_attrs["id"],
          select: %Post{
            id: p.id,
            thread_id: p.thread_id,
            content: p.content,
            metadata: p.metadata,
            user_id: p.user_id,
            created_at: p.created_at,
            updated_at: p.updated_at
          }

      Repo.one(query)
      |> update_changeset(post_attrs, authed_user)
      |> Repo.update!(returning: true)
      |> Repo.preload(:thread)
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

  @doc """
  Get number of posts by a specific `User` between two dates, used for `UserActivity` algorithm.
  """
  @spec count_by_user_id_in_range(
          user_id :: non_neg_integer,
          range_start :: NaiveDateTime.t(),
          range_end :: NaiveDateTime.t()
        ) ::
          non_neg_integer
  def count_by_user_id_in_range(user_id, range_start, range_end) do
    query =
      from p in Post,
        select: count(p.id),
        where:
          p.user_id == ^user_id and p.created_at > ^range_start and p.created_at <= ^range_end

    Repo.one(query)
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
            p.content ->> \'body\' as body, p.content ->> \'body_html\' as body_html, p.metadata, p.deleted, p.locked, p.created_at,
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
      body_html: p1.body_html,
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
  @spec find_by_id(id :: non_neg_integer, preload_user_roles :: boolean | nil) :: t()
  def find_by_id(id, preload_user_roles \\ false) when is_integer(id) do
    query =
      from p in Post,
        where: p.id == ^id,
        preload: [:thread, user: :profile]

    results = Repo.one(query)

    if preload_user_roles,
      do: results |> Repo.preload(user: :roles),
      else: results
  end

  @doc """
  Used to correct the text search vector for post after being modified for mentions
  """
  # TODO(akinsey): add tsv column to post, verify this is working
  @spec fix_text_search_vector(post_attrs :: map()) :: {non_neg_integer(), nil}
  def fix_text_search_vector(post_attrs) do
    query =
      from p in Post,
        update: [
          set: [
            tsv:
              fragment(
                """
                  setweight(to_tsvector('simple', COALESCE(?,'')), 'A') ||
                  setweight(to_tsvector('simple', COALESCE(?,'')), 'B')
                """,
                ^post_attrs["title"],
                ^post_attrs["body_original"]
              )
          ]
        ],
        where: p.id == ^post_attrs["id"]

    Repo.update_all(query, [])
  end

  ## === Private Helper Fucntions ===

  defp format_update_attrs(post, attrs, authed_user) do
    # format attrs for casting
    attrs =
      attrs
      |> Map.put(:content, %{
        :body => attrs["body"],
        :body_html => attrs["body_html"],
        :title => attrs["title"]
      })
      |> Map.put(:thread_id, post.thread_id)
      |> Map.put(:metadata, post.metadata)
      |> Map.put(:id, post.id)

    # update metadata if post is being edited by someone who is not the post author
    metadata =
      if authed_user.id == post.user_id,
        do:
          (attrs.metadata || %{}) |> Map.delete(:edited_by_id) |> Map.delete(:edited_by_username),
        else:
          (attrs.metadata || %{})
          |> Map.put(:edited_by_id, authed_user.id)
          |> Map.put(:edited_by_username, authed_user.username)

    # if metadata has nothing in it, set to nil
    attrs =
      if metadata == %{},
        do: Map.put(attrs, :metadata, nil),
        else: Map.put(attrs, :metadata, metadata)

    # calculate if post is outside 10 minute edit window
    now = NaiveDateTime.utc_now()

    time_since_last_edit_ms =
      abs(NaiveDateTime.diff(post.updated_at || post.created_at, now) * 1000)

    outside_edit_window = time_since_last_edit_ms > @edit_window_ms

    # update updated_at field if outside of 10 min grace period,
    # or if a moderator is editing a user's post
    now = NaiveDateTime.truncate(now, :second)

    attrs =
      if (attrs.metadata != nil && Map.keys(attrs.metadata) != []) || outside_edit_window,
        do: Map.put(attrs, :updated_at, now),
        else: attrs

    # remove old keys after formatting attrs
    attrs
    |> Map.delete("id")
    |> Map.delete("body")
    |> Map.delete("body_html")
    |> Map.delete("body_original")
    |> Map.delete("mentioned_ids")
    |> Map.delete("thread_id")
    |> Map.delete("user_id")
    |> Map.delete("title")
  end
end
