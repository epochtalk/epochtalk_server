defmodule EpochtalkServer.Models.Board do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Category
  alias EpochtalkServer.Models.BoardMapping
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.MetadataBoard

  @moduledoc """
  `Board` model, for performing actions relating to forum boards
  """
  @type t :: %__MODULE__{
          id: non_neg_integer | nil,
          category: Category.t() | term(),
          name: String.t() | nil,
          slug: String.t() | nil,
          description: String.t() | nil,
          post_count: non_neg_integer | 0,
          thread_count: non_neg_integer | 0,
          viewable_by: non_neg_integer | nil,
          postable_by: non_neg_integer | nil,
          right_to_left: boolean | false,
          created_at: NaiveDateTime.t() | nil,
          imported_at: NaiveDateTime.t() | nil,
          meta: map() | nil
        }
  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :slug,
             :description,
             :post_count,
             :thread_count,
             :viewable_by,
             :postable_by,
             :right_to_left,
             :created_at,
             :imported_at,
             :meta
           ]}
  schema "boards" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :post_count, :integer, default: 0
    field :thread_count, :integer, default: 0
    field :viewable_by, :integer
    field :postable_by, :integer
    field :right_to_left, :boolean, default: false
    field :created_at, :naive_datetime
    field :imported_at, :naive_datetime
    field :updated_at, :naive_datetime
    field :meta, :map
    many_to_many :category, Category, join_through: BoardMapping
  end

  ## === Changesets Functions ===

  @doc """
  Create generic changeset for `Board` model
  """
  @spec changeset(
          board :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(board, attrs) do
    board
    |> cast(attrs, [
      :id,
      :name,
      :slug,
      :description,
      :post_count,
      :thread_count,
      :viewable_by,
      :postable_by,
      :created_at,
      :imported_at,
      :updated_at,
      :meta
    ])
    |> cast_assoc(:categories)
    |> unique_constraint(:id, name: :boards_pkey)
    |> unique_constraint(:slug, name: :boards_slug_index)
  end

  ## === Changesets Functions ===

  @doc """
  Create changeset for creation of `Board` model
  """
  @spec create_changeset(board :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def create_changeset(board, attrs) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    attrs =
      attrs
      |> Map.put(:created_at, now)
      |> Map.put(:updated_at, now)

    board
    |> cast(attrs, [
      :name,
      :slug,
      :description,
      :viewable_by,
      :postable_by,
      :right_to_left,
      :created_at,
      :updated_at,
      :meta
    ])
    |> unique_constraint(:id, name: :boards_pkey)
    |> unique_constraint(:slug, name: :boards_slug_index)
  end

  ## === Database Functions ===

  @doc """
  Creates a new `Board` in the database
  """
  @spec create(board_attrs :: map()) :: {:ok, board :: t()} | {:error, Ecto.Changeset.t()}
  def create(board_attrs) do
    board_cs = create_changeset(%Board{}, board_attrs)

    case Repo.insert(board_cs) do
      {:ok, db_board} ->
        case MetadataBoard.insert(%MetadataBoard{board_id: db_board.id}) do
          {:ok, _} -> {:ok, db_board}
          {:error, cs} -> {:error, cs}
        end

      {:error, cs} ->
        {:error, cs}
    end
  end

  @doc """
  Given an id and moderated property, returns boolean indicating if `Board` allows self moderation
  """
  @spec allows_self_moderation?(id :: non_neg_integer, moderated :: boolean) ::
          allowed :: boolean
  def allows_self_moderation?(id, true) do
    query =
      from b in Board,
        where: b.id == ^id,
        select: b.meta["disable_self_mod"]

    query
    |> Repo.one() || false
  end

  # pass through if model being created doesn't have "moderated" property set
  def allows_self_moderation?(_id, false), do: true
  def allows_self_moderation?(_id, nil), do: true

  @doc """
  Determines if the provided `user_priority` has write access to the board that contains the thread
  the specified `thread_id`
  """
  # TODO(akinsey): Should this check against banned user_priority?
  @spec get_write_access_by_thread_id(
          thread_id :: non_neg_integer,
          user_priority :: non_neg_integer
        ) ::
          {:ok, can_write :: boolean} | {:error, :board_does_not_exist}
  def get_write_access_by_thread_id(thread_id, user_priority) do
    query =
      from b in Board,
        left_join: t in Thread,
        on: t.board_id == b.id,
        where: t.id == ^thread_id,
        select: %{postable_by: b.postable_by}

    query
    |> Repo.one()
    |> get_write_access(user_priority)
  end

  @doc """
  Determines if the provided `user_priority` has write access to the board with the specified `id`
  """
  @spec get_write_access_by_id(id :: non_neg_integer, user_priority :: non_neg_integer) ::
          {:ok, can_write :: boolean} | {:error, :board_does_not_exist}
  def get_write_access_by_id(id, user_priority) do
    query =
      from b in Board,
        where: b.id == ^id,
        select: %{postable_by: b.postable_by}

    query
    |> Repo.one()
    |> get_write_access(user_priority)
  end

  @doc """
  Determines if the provided `user_priority` has read access to the `Board` that contains the thread
  with the specified `thread_id`. If the user doesn't have read access to the parent of the specified
  `Board`, the user does not have read access to the `Board` either.

  DEVELOPER NOTE(akinsey): This method replaces Threads.getThreadsBoardInBoardMapping function from the node
  server. The previous naming convention was confusing as this is just checking read access to the board
  """
  # TODO(akinsey): Should this check against banned user_priority?
  @spec get_read_access_by_thread_id(
          thread_id :: non_neg_integer,
          user_priority :: non_neg_integer
        ) ::
          {:ok, can_read :: boolean} | {:error, :board_does_not_exist}
  def get_read_access_by_thread_id(thread_id, user_priority) do
    query =
      from t in Thread,
        where: t.id == ^thread_id,
        select: t.board_id

    id = Repo.one(query)

    if id, do: get_read_access_by_id(id, user_priority), else: {:error, :board_does_not_exist}
  end

  @doc """
  Determines if the provided `user_priority` has read access to the `Board` with the specified `id`.
  If the user doesn't have read access to the parent of the specified `Board`, the user does not have
  read access to the `Board` either.

  DEVELOPER NOTE(akinsey): This method replaces Boards.getBoardInBoardMapping function from the node
  server. The previous naming convention was confusing as this is just checking read access to the board
  """
  # TODO(akinsey): Should this check against banned user_priority?
  @spec get_read_access_by_id(id :: non_neg_integer, user_priority :: non_neg_integer) ::
          {:ok, can_read :: boolean} | {:error, :board_does_not_exist}
  def get_read_access_by_id(id, user_priority) do
    Board
    |> recursive_ctes(true)
    |> with_cte("find_parent", as: ^get_parent_query(id))
    |> join(:inner, [b], fp in "find_parent", on: b.id == fp.board_id)
    |> join(:left, [b, fp], c in Category, on: c.id == fp.category_id)
    |> select([b, fp, c], %{
      board_id: fp.board_id,
      parent_id: fp.parent_id,
      category_id: fp.category_id,
      cat_viewable_by: c.viewable_by,
      board_viewable_by: b.viewable_by
    })
    |> Repo.all()
    |> case do
      [] ->
        {:error, :board_does_not_exist}

      board_and_parents ->
        # not readable if nothing in list, readable if viewable_by is nil, otherwise check viewable_by against user priority
        can_read =
          Enum.reduce(board_and_parents, length(board_and_parents) > 0, fn i, acc ->
            boards_viewable =
              not (is_integer(i.board_viewable_by) && user_priority > i.board_viewable_by)

            cats_viewable =
              not (is_integer(i.cat_viewable_by) && user_priority > i.cat_viewable_by)

            acc && boards_viewable && cats_viewable
          end)

        {:ok, can_read}
    end
  end

  @doc """
  Fetches list of boards that authed `User` has priority to view. Used for `Board` movelist,
  a `Thread` moderation feature.
  """
  @spec movelist(user_priority :: non_neg_integer) :: [Board.t()] | []
  def movelist(user_priority) when is_integer(user_priority) do
    # fetches board data, handles fetching parent_id of when parent is a board or category
    query = """
    SELECT CASE WHEN category_id IS NULL THEN parent_id ELSE category_id END as parent_id, board_id as id, (SELECT viewable_by FROM boards WHERE board_id = id), (SELECT name FROM boards WHERE board_id = id), CASE WHEN category_id IS NULL THEN (SELECT name FROM boards WHERE parent_id = id) ELSE (SELECT name FROM categories WHERE category_id = id) END as parent_name, view_order FROM board_mapping
    """

    # cannot recreate "CASE WHEN" statement with ecto syntax, quering raw sql data instead
    raw_data = Ecto.Adapters.SQL.query!(Repo, query)

    # convert raw sql query results into list of board maps
    Enum.reduce(raw_data.rows, [], fn row, boards ->
      board_data =
        raw_data.columns
        |> Enum.with_index()
        |> Enum.reduce(%{}, fn {key, row_index}, board_map ->
          Map.put(board_map, String.to_atom(key), Enum.at(row, row_index))
        end)

      boards ++ [board_data]
    end)
    # filter out boards that user doesn't have permission to see
    |> Enum.filter(fn board ->
      if board.viewable_by != 0 && is_nil(board.viewable_by),
        do: true,
        else: user_priority <= board.viewable_by
    end)
  end

  @doc """
  Converts a board's `slug` to `id`
  """
  @spec slug_to_id(slug :: String.t()) ::
          {:ok, id :: non_neg_integer} | {:error, :board_does_not_exist}
  def slug_to_id(slug) when is_binary(slug) do
    query =
      from b in Board,
        where: b.slug == ^slug,
        select: b.id

    id = Repo.one(query)

    if id,
      do: {:ok, id},
      else: {:error, :board_does_not_exist}
  end

  @doc """
  Find a `Board` by it's `id`
  """
  @spec find_by_id(id :: non_neg_integer) ::
          {:ok, t()} | {:error, :board_does_not_exist}
  def find_by_id(id) when is_integer(id) do
    query = from b in Board, where: b.id == ^id

    board = Repo.one(query)

    if board,
      do: {:ok, board},
      else: {:error, :board_does_not_exist}
  end

  @doc """
  Returns boolean indicating if `Board` has `Post` edit disabled, which is determined by
  the `post_edit_diabled` setting within the `meta` field of the `Board`
  """
  @spec is_post_edit_disabled_by_thread_id(
          thread_id :: non_neg_integer,
          post_created_at :: NaiveDateTime.t()
        ) :: boolean
  def is_post_edit_disabled_by_thread_id(thread_id, post_created_at) when is_integer(thread_id) do
    query =
      from b in Board,
        left_join: t in Thread,
        on: t.board_id == b.id,
        where: t.id == ^thread_id,
        select: b.meta["disable_post_edit"]

    disable_post_edit = Repo.one(query)

    # check time elapsed if post edit is disabled
    editing_disabled =
      if is_integer(disable_post_edit) and disable_post_edit > -1 do
        current_time =
          NaiveDateTime.utc_now()
          |> DateTime.from_naive!("Etc/UTC")
          |> DateTime.to_unix(:millisecond)

        post_created_at =
          post_created_at |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(:millisecond)

        editable_for_mins = disable_post_edit * 60 * 1000

        current_time - post_created_at >= editable_for_mins
      else
        # diable_post_edit not set
        false
      end

    editing_disabled
  end

  @doc """
  Used to obtain breadcrumb data for a specific `Board` given it's `slug`
  """
  @spec breadcrumb(slug :: String.t()) ::
          {:ok, board :: t()} | {:error, :board_does_not_exist}
  def breadcrumb(slug) when is_binary(slug) do
    case slug_to_id(slug) do
      {:ok, id} ->
        Board
        |> recursive_ctes(true)
        |> with_cte("find_parent", as: ^get_parent_query(id))
        |> join(:inner, [b], fp in "find_parent", on: b.id == fp.board_id)
        |> join(:left, [b, fp], b2 in Board, on: b2.id == fp.parent_id)
        |> join(:left, [b, fp, b2], c in Category, on: c.id == fp.category_id)
        |> select([b, fp, b2, c], %{
          id: b.id,
          name: b.name,
          parent_slug: b2.slug,
          board_id: fp.board_id,
          parent_id: fp.parent_id,
          category_id: fp.category_id
        })
        |> Repo.all()
        |> case do
          [] ->
            {:error, :board_does_not_exist}

          board_and_parents ->
            {:ok, board_and_parents}
        end

      {:error, :board_does_not_exist} ->
        {:error, :board_does_not_exist}
    end
  end

  ## ======== Private Helpers ========

  defp get_write_access(board, user_priority) do
    if board do
      # allow write if postable_by is nil
      can_write = is_nil(board.postable_by)
      # if postable_by is an integer, check against user priority
      can_write =
        if is_integer(board.postable_by),
          do: user_priority <= board.postable_by,
          else: can_write

      {:ok, can_write}
    else
      {:error, :board_does_not_exist}
    end
  end

  defp get_parent_query(id) when is_integer(id) do
    find_parent_initial_query =
      BoardMapping
      |> where([bm], bm.board_id == ^id)
      |> select([bm], %{
        board_id: bm.board_id,
        parent_id: bm.parent_id,
        category_id: bm.category_id
      })

    find_parent_recursion_query =
      BoardMapping
      |> join(:inner, [bm], fp in "find_parent", on: bm.board_id == fp.parent_id)
      |> select([bm], %{
        board_id: bm.board_id,
        parent_id: bm.parent_id,
        category_id: bm.category_id
      })

    find_parent_initial_query
    |> union(^find_parent_recursion_query)
  end
end
