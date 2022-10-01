defmodule EpochtalkServer.Models.BoardMapping do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.BoardMapping
  alias EpochtalkServer.Models.Category

  @primary_key false
  schema "board_mapping" do
    belongs_to :board, Board, primary_key: true
    belongs_to :parent, Board, primary_key: true
    belongs_to :category, Category, primary_key: true
    field :view_order, :integer
  end

  ## === Changesets Functions ===

  def changeset(board_mapping, attrs) do
    board_mapping
    |> cast(attrs, [:board_id, :parent_id, :category_id, :view_order])
    |> foreign_key_constraint(:parent_id, name: :board_mapping_parent_id_fkey)
    |> unique_constraint([:board_id, :parent_id], name: :board_mapping_board_id_parent_id_index)
    |> unique_constraint([:board_id, :category_id], name: :board_mapping_board_id_category_id_index)
  end

  ## === Database Functions ===

  def insert(%BoardMapping{} = board_mapping), do: Repo.insert(board_mapping)

  def delete_board(id) do
    query = from bm in BoardMapping,
      where: bm.board_id == ^id
    Repo.delete_all(query)
  end

  def update(board_mapping_list) do
    Repo.transaction(fn ->
      Enum.each(board_mapping_list, &BoardMapping.update(&1, Map.get(&1, :type)))
    end)
  end
  def update(cat, "category"), do: Category.update_for_board_mapping(cat)
  def update(uncat, "uncategorized"), do: delete_board(Map.get(uncat, :id))
  def update(board, "board") do
    delete_board(Map.get(board, :id))
    %BoardMapping{}
    |> changeset(Map.put(board, :board_id, Map.get(board, :id)))
    |> Repo.insert
  end
end
