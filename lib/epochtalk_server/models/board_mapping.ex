defmodule EpochtalkServer.Models.BoardMapping do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.MetadataBoard
  alias EpochtalkServer.Models.BoardMapping
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.Category

  @moduledoc """
  `BoardMapping` model, for performing actions relating to mapping forum boards and categories
  """
  @type t :: %__MODULE__{
          board: Board.t() | term(),
          parent: Board.t() | term(),
          category: Category.t() | term(),
          view_order: non_neg_integer | nil
        }
  @derive {Jason.Encoder,
           only: [
             :board_id,
             :parent_id,
             :category_id,
             :view_order,
             :stats,
             :thread,
             :sticky_thread_count
           ]}
  @primary_key false
  schema "board_mapping" do
    belongs_to :board, Board, primary_key: true
    belongs_to :parent, Board, primary_key: true
    belongs_to :category, Category, primary_key: true
    field :view_order, :integer
    field :stats, :map, virtual: true
    field :thread, :map, virtual: true
    field :sticky_thread_count, :map, virtual: true
  end

  ## === Changesets Functions ===

  @doc """
  Create generic changeset for `BoardMapping` model
  """
  @spec changeset(board_mapping :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def changeset(board_mapping, attrs) do
    board_mapping
    |> cast(attrs, [:board_id, :parent_id, :category_id, :view_order])
    |> foreign_key_constraint(:parent_id, name: :board_mapping_parent_id_fkey)
    |> unique_constraint([:board_id, :parent_id], name: :board_mapping_board_id_parent_id_index)
    |> unique_constraint([:board_id, :category_id],
      name: :board_mapping_board_id_category_id_index
    )
  end

  ## === Database Functions ===

  @doc """
  Deletes a `Board` from the `BoardMapping`
  """
  @spec delete_board_by_id(board_id :: integer()) :: {non_neg_integer(), nil | [term()]}
  def delete_board_by_id(id) when is_integer(id) do
    query =
      from bm in BoardMapping,
        where: bm.board_id == ^id

    Repo.delete_all(query)
  end

  @doc """
  Updates `BoardMapping` in the database
  """
  @spec update(board_mapping_list :: [%{}]) ::
          {:ok, Ecto.Changeset.t()} | {:error, Ecto.Changeset.t()} | {:error, any()}
  def update(board_mapping_list) do
    Repo.transaction(fn ->
      Enum.each(board_mapping_list, &update(&1, Map.get(&1, :type)))
    end)
  end

  @doc """
  Returns BoardMapping with loaded boards and relevant metadata
  """
  # TODO(akinsey): writing this assuming other models will update metadata board table properly.
  # Old implementation was querying metadata boards then filling in holes in the data after the fact.
  @spec all(opts :: list() | nil) :: [t()]
  def all(opts \\ []) do
    stripped = Keyword.get(opts, :stripped, false)

    query =
      if stripped do
        from bm in BoardMapping,
          left_join: b in Board,
          on: bm.board_id == b.id,
          select_merge: %{
            board: %{id: b.id, slug: b.slug, name: b.name, viewable_by: b.viewable_by}
          }
      else
        sticky_count_subquery =
          from t in Thread,
            where: t.sticky == true,
            select: %{board_id: t.board_id, sticky_thread_count: count(t.id)},
            group_by: [t.board_id]

        from bm in BoardMapping,
          left_join: mb in MetadataBoard,
          on: bm.board_id == mb.board_id,
          left_join: t in Thread,
          on: mb.last_thread_id == t.id,
          left_join: s in subquery(sticky_count_subquery),
          on: bm.board_id == s.board_id,
          select_merge: %{
            stats: mb,
            thread: %{
              last_thread_slug: t.slug,
              last_thread_post_count: t.post_count,
              last_thread_created_at: t.created_at,
              last_thread_updated_at: t.updated_at
            },
            sticky_thread_count: s.sticky_thread_count
          },
          preload: [:board]
      end

    Repo.all(query)
  end

  ## === Private Helper Functions ===

  defp update(cat, "category"), do: Category.update_for_board_mapping(cat)
  defp update(uncat, "uncategorized"), do: BoardMapping.delete_board_by_id(Map.get(uncat, :id))

  defp update(board, "board") do
    BoardMapping.delete_board_by_id(Map.get(board, :id))

    %BoardMapping{}
    |> changeset(Map.put(board, :board_id, Map.get(board, :id)))
    |> Repo.insert()
  end
end
