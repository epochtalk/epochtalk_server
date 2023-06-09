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
          post_count: non_neg_integer | nil,
          thread_count: non_neg_integer | nil,
          viewable_by: non_neg_integer | nil,
          postable_by: non_neg_integer | nil,
          right_to_left: boolean | nil,
          created_at: NaiveDateTime.t() | nil,
          imported_at: NaiveDateTime.t() | nil,
          meta: map() | nil
        }
  schema "boards" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :post_count, :integer
    field :thread_count, :integer
    field :viewable_by, :integer
    field :postable_by, :integer
    field :right_to_left, :boolean
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
  def create(board) do
    board_cs = create_changeset(%Board{}, board)

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
  Determines if the provided `user_priority` has write access to the board that contains the thread
  the specified `thread_idid`

  TODO(akinsey): Should this check against banned user_priority?
  """
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

  TODO(akinsey): Should this check against banned user_priority?
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

  TODO(akinsey): Should this check against banned user_priority?
  """
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

  TODO(akinsey): Should this check against banned user_priority?
  """
  @spec get_read_access_by_id(id :: non_neg_integer, user_priority :: non_neg_integer) ::
          {:ok, can_read :: boolean} | {:error, :board_does_not_exist}
  def get_read_access_by_id(id, user_priority) do
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

    find_parent_query =
      find_parent_initial_query
      |> union(^find_parent_recursion_query)

    board_and_parents =
      Board
      |> recursive_ctes(true)
      |> with_cte("find_parent", as: ^find_parent_query)
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

    # not readable if nothing in list, readable if viewable_by is nil, otherwise check viewable_by against user priority
    can_read =
      Enum.reduce(board_and_parents, length(board_and_parents) > 0, fn i, acc ->
        boards_viewable =
          not (is_integer(i.board_viewable_by) && user_priority > i.board_viewable_by)

        cats_viewable = not (is_integer(i.cat_viewable_by) && user_priority > i.cat_viewable_by)
        acc && boards_viewable && cats_viewable
      end)

    {:ok, can_read}
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
    query =
      from b in Board,
        where: b.id == ^id

    board = Repo.one(query)

    if board,
      do: {:ok, board},
      else: {:error, :board_does_not_exist}
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
end
