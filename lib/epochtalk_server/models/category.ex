defmodule EpochtalkServer.Models.Category do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.Category
  alias EpochtalkServer.Models.BoardMapping
  
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

  def changeset(board, attrs) do
    board
    |> cast(attrs, [:id, :name, :view_order, :viewable_by, :postable_by, :created_at, :imported_at, :updated_at, :meta])
    |> unique_constraint(:id, name: :categories_pkey)
  end
  def insert(%Category{} = category), do: Repo.insert(category)
end
