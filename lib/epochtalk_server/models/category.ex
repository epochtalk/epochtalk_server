defmodule EpochtalkServer.Models.Category do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.Category
  alias EpochtalkServer.Models.BoardMapping

  @moduledoc """
  `Category` model, for performing actions relating to forum categories
  """
  @type t :: %__MODULE__{
          id: non_neg_integer | nil,
          name: String.t() | nil,
          view_order: non_neg_integer | nil,
          viewable_by: non_neg_integer | nil,
          postable_by: non_neg_integer | nil,
          created_at: NaiveDateTime.t() | nil,
          imported_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil,
          meta: map() | nil,
          boards: [Board.t()] | term()
        }
  schema "categories" do
    field :name, :string
    field :view_order, :integer
    field :viewable_by, :integer
    field :postable_by, :integer
    field :created_at, :naive_datetime
    field :imported_at, :naive_datetime
    field :updated_at, :naive_datetime
    field :meta, :map
    many_to_many :boards, Board, join_through: BoardMapping
  end

  ## === Changesets Functions ===

  @doc """
  Create generic changeset for `Category` model
  """
  @spec changeset(category :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def changeset(category, attrs) do
    category
    |> cast(attrs, [
      :id,
      :name,
      :view_order,
      :viewable_by,
      :postable_by,
      :created_at,
      :imported_at,
      :updated_at,
      :meta
    ])
    |> unique_constraint(:id, name: :categories_pkey)
  end

  @doc """
  Creates changeset for inserting a new `Category` model
  """
  @spec create_changeset(category :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def create_changeset(category, attrs) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    attrs =
      attrs
      |> Map.put(:created_at, now)
      |> Map.put(:updated_at, now)

    category
    |> cast(attrs, [:name, :viewable_by, :created_at, :updated_at])
  end

  @doc """
  Creates changeset for updating an existing `Category` model
  """
  @spec update_for_board_mapping_changeset(category :: t(), attrs :: map() | nil) ::
          Ecto.Changeset.t()
  def update_for_board_mapping_changeset(category, attrs) do
    category
    |> cast(attrs, [:id, :name, :view_order, :viewable_by])
    |> unique_constraint(:id, name: :categories_pkey)
  end

  ## === Database Functions ===

  @doc """
  Creates a new `Category` in the database
  """
  @spec create(category_attrs :: map()) :: {:ok, category :: t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    category_cs = create_changeset(%Category{}, attrs)
    Repo.insert(category_cs)
  end

  @doc """
  Updates an existing `Category` in the database, used by board mapping to recategorize boards
  """
  @spec update_for_board_mapping(category_map :: %{id: id :: integer}) ::
          {:ok, category :: t()} | {:error, Ecto.Changeset.t()}
  def update_for_board_mapping(%{id: id} = category_map) do
    %Category{id: id}
    |> update_for_board_mapping_changeset(category_map)
    |> Repo.update()
  end

  @doc """
  Returns a list of all categories
  """
  @spec all() :: [t()]
  def all(), do: Repo.all(from Category)
end
