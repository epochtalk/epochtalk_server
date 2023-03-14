defmodule EpochtalkServer.Models.Board do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Category
  alias EpochtalkServer.Models.BoardMapping
  alias EpochtalkServer.Models.Board
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

    board = Repo.one(query)

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

  @doc """
  Converts a board's `slug` to `id`
  """
  @spec slug_to_id(slug :: String.t()) ::
          {:ok, id :: non_neg_integer} | {:error, :board_does_not_exist}
  def slug_to_id(slug) when is_binary(slug) do
    query = from b in Board,
      where: b.slug == ^slug,
      select: b.id

    id = Repo.one(query)

    if id,
      do: {:ok, id},
      else: {:error, :board_does_not_exist}
  end
end
