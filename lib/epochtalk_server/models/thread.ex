defmodule EpochtalkServer.Models.Thread do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.MetadataThread
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.Post

  @moduledoc """
  `Thread` model, for performing actions relating to forum threads
  """
  @type t :: %__MODULE__{
          id: non_neg_integer | nil,
          board_id: non_neg_integer | nil,
          locked: boolean | nil,
          sticky: boolean | nil,
          slug: String.t() | nil,
          moderated: boolean | nil,
          post_count: non_neg_integer | nil,
          created_at: NaiveDateTime.t() | nil,
          imported_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }
  schema "threads" do
    belongs_to :board, Board
    field :locked, :boolean
    field :sticky, :boolean
    field :slug, :string
    field :moderated, :boolean
    field :post_count, :integer
    field :created_at, :naive_datetime
    field :imported_at, :naive_datetime
    field :updated_at, :naive_datetime
    has_many :posts, Post
    # field :smf_topic, :map, virtual: true
  end

  ## === Changesets Functions ===

  @doc """
  Create generic changeset for `Thread` model
  """
  @spec changeset(thread :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def changeset(thread, attrs) do
    thread
    |> cast(attrs, [
      :id,
      :board_id,
      :locked,
      :sticky,
      :slug,
      :moderated,
      :post_count,
      :created_at,
      :imported_at,
      :updated_at
    ])
    |> unique_constraint(:id, name: :threads_pkey)
    |> unique_constraint(:slug, name: :threads_slug_index)
    |> foreign_key_constraint(:board_id, name: :threads_board_id_fkey)
  end

  ## === Database Functions ===

  @doc """
  Returns recent threads accounting for user priority and user's ignored boards
  """
  @spec recent(user :: User.t(), user_priority :: non_neg_integer, opts :: list() | nil) :: [t()]
  def recent(_user, _user_priority, opts \\ []) do
    limit = Keyword.get(opts, :limit, 5)
    # IO.inspect user
    # IO.inspect user_priority
    query =
      from Thread,
        order_by: [desc: :updated_at],
        limit: ^limit

    Repo.all(query)
  end

  def page_by_board_id(board_id, page \\ 1, opts \\ []) do
    user_id = Keyword.get(opts, :user_id)
    per_page = Keyword.get(opts, :per_page, 25)
    field = Keyword.get(opts, :field, "updated_at")
    reversed = Keyword.get(opts, :desc, false)
    offset = (page * opts[:per_page]) - opts[:per_page]

    opts = opts
      |> Keyword.put(:user_id, user_id)
      |> Keyword.put(:per_page, per_page)
      |> Keyword.put(:field, field)
      |> Keyword.put(:reversed, reversed)
      |> Keyword.put(:offset, offset)

    %{
      sticky: sticky_by_board_id(board_id, page, opts),
      normal: normal_by_board_id(board_id, page, opts)
    }
  end

  def sticky_by_board_id(board_id, page, opts) when page == 1 do
    # base inner_query fetch thread and metadata thread
    inner_query = Thread
    |> join(:left, [t2], mt in MetadataThread, on: t2.id == mt.thread_id)
    |> where([t2, mt], t2.board_id == ^board_id and t2.sticky == true and not is_nil(t2.updated_at))
    |> select([t2, mt], %{id: t2.id, updated_at: t2.updated_at, views: mt.views, created_at: t2.created_at, post_count: t2.post_count})
    |> limit(^opts[:per_page])
    |> offset(^opts[:offset])

    # handle sort field and direction
    field = String.to_atom(opts[:field])
    direction = if opts[:reversed], do: :desc, else: :asc

    # sort by field in joined metadata thread table if sort field is 'view'
    inner_query = if field == :views,
      do: inner_query |> order_by([t, mt], [{^direction, mt.views}]),
      else: inner_query |> order_by([t], [{^direction, field(t, ^field)}])

    # outer query
    query = from(tlist in subquery(inner_query))
      # join thread info
      |> join(:left_lateral, [tlist], t in fragment("""
          SELECT t1.locked, t1.sticky, t1.slug, t1.moderated,
            t1.post_count, t1.created_at, t1.updated_at, mt.views,
            (SELECT EXISTS ( SELECT 1 FROM polls WHERE thread_id = ? )) as poll,
            (SELECT time FROM users.thread_views WHERE thread_id = ? AND user_id = ?)
          FROM threads t1
          LEFT JOIN metadata.threads mt ON ? = mt.thread_id
          WHERE t1.id = ?
        """, tlist.id, tlist.id, ^opts[:user_id], tlist.id, tlist.id))
      # join thread title and author info
      |> join(:left_lateral, [tlist], p in fragment("""
          SELECT p1.content ->> \'title\' as title, p1.user_id,
            u.username, u.deleted as user_deleted
          FROM posts p1
          LEFT JOIN users u ON p1.user_id = u.id
          WHERE p1.thread_id = ?
          ORDER BY p1.created_at
          LIMIT 1
        """, tlist.id))
      # join post id and post position
      |> join(:left_lateral, [tlist, t], tv in fragment("""
          SELECT id, position
          FROM posts
          WHERE thread_id = ? AND created_at >= ?
          ORDER BY created_at
          LIMIT 1
        """, tlist.id, t.time))
      # join last post info
      |> join(:left_lateral, [tlist], pl in fragment("""
          SELECT p.id AS last_post_id, p.position, p.created_at, p.deleted,
           u.id, u.username, u.deleted as user_deleted, up.avatar
         FROM posts p
         LEFT JOIN users u ON p.user_id = u.id
         LEFT JOIN users.profiles up ON p.user_id = up.user_id
         WHERE p.thread_id = ?
         ORDER BY p.created_at DESC
         LIMIT 1
        """, tlist.id))
      |> select([tlist, t, p, tv, pl], %{
          id: tlist.id,
          slug: t.slug,
          locked: t.locked,
          sticky: t.sticky,
          moderated: t.moderated,
          poll: t.poll,
          created_at: t.created_at,
          updated_at: t.updated_at,
          post_count: t.post_count,
          last_viewed: t.time,
          view_count: tlist.views,
          title: p.title,
          user_id: p.user_id,
          username: p.username,
          user_deleted: p.user_deleted,
          post_id: tv.id,
          post_position: tv.position,
          last_post_id: pl.last_post_id,
          last_post_position: pl.position,
          last_post_created_at: pl.created_at,
          last_post_deleted: pl.deleted,
          last_post_user_id: pl.id,
          last_post_username: pl.username,
          last_post_user_deleted: pl.user_deleted,
          last_post_avatar: pl.avatar
        })
    Repo.all(query)
  end
  def sticky_by_board_id(_board_id, page, _opts) when page != 1, do: []

  def normal_by_board_id(board_id, _page, opts) do
    normal_count_query = from b in Board, where: b.id == ^board_id, select: b.thread_count
    sticky_count_query = from t in Thread, where: t.board_id == ^board_id and t.sticky == true, select: count(t.id)
    normal_thread_count = normal_count_query |> Repo.one()
    sticky_thread_count = sticky_count_query |> Repo.one()

    thread_count = if normal_thread_count, do: normal_thread_count - sticky_thread_count
    IO.inspect opts
    IO.inspect thread_count
    IO. inspect opts[:offset] > floor(thread_count / 2)
    # determine wheter to start from front or back
    opts = if not is_nil(thread_count) and opts[:offset] > floor(thread_count / 2) do
      # invert reverse
      reversed = !opts[:reversed]
      opts = Keyword.put(opts, :reversed, reversed)

      # calculate new per_page
      per_page = if thread_count <= opts[:offset] + opts[:per_page],
        do: thread_count - opts[:offset],
        else: opts[:per_page]
      opts = Keyword.put(opts, :per_page, per_page)

      # calculate new offset after modifying per_page
      offset = if thread_count <= opts[:offset] + opts[:per_page],
        do: 0,
        else: thread_count - opts[:offset] - opts[:per_page]
      Keyword.put(opts, :offset, offset)
    else
      opts
    end
    IO.inspect opts

    %{normal_thread_count: normal_thread_count, sticky_thread_count: sticky_thread_count}
  end
end
