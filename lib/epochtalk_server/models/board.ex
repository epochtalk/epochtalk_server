defmodule EpochtalkServer.Models.Board do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Models.Category
  alias EpochtalkServer.Models.BoardMapping

  schema "boards" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :post_count, :integer
    field :thread_count, :integer
    field :viewable_by, :integer
    field :postable_by, :integer
    field :created_at, :naive_datetime
    field :imported_at, :naive_datetime
    field :updated_at, :naive_datetime
    field :meta, :map
    many_to_many :categories, Category, join_through: BoardMapping
  end

  def changeset(board, attrs) do
    board
    |> cast(attrs, [:id, :name, :slug, :description, :post_count, :thread_count, :viewable_by, :postable_by, :created_at, :imported_at, :updated_at, :meta])
    |> cast_assoc(:categories)
    |> unique_constraint(:id, name: :boards_pkey)
    |> unique_constraint(:slug, name: :boards_slug_index)
  end
  def insert(%Board{} = board), do: Repo.insert(board)
end
