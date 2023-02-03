defmodule EpochtalkServerWeb.BoardView do
  use EpochtalkServerWeb, :view

  @moduledoc """
  Renders and formats `User` data, in JSON format for frontend
  """

  @doc """
  Renders whatever data it is passed when template not found. Data pass through
  for rendering misc responses (ex: {found: true} or {success: true})
  ## Example
      iex> EpochtalkServerWeb.BoardView.render("DoesNotExist.json", data: %{anything: "abc"})
      %{anything: "abc"}
      iex> EpochtalkServerWeb.BoardView.render("DoesNotExist.json", data: %{success: true})
      %{success: true}
  """
  def template_not_found(_template, %{data: data}), do: data

  @doc """
  Renders paginated `User` mentions. If extended is true returns additional `Board` and `Post` details.
  """
  def render("by_category.json", %{
        categories: categories,
        board_mapping: board_mapping
      }) do
    IO.inspect board_mapping
    # iterate each category
    categories = Enum.reduce(categories, [], fn category, acc ->
      # look through board mapping, filter and process child boards for the current category
      category = process_children_from_board_mapping(:category_id, board_mapping, :boards, category)
      acc ++ [category]
    end)

    categories
  end

  defp process_children_from_board_mapping(board_mapping_key, board_mapping, child_key, parent) do
    # look through board mapping, filter boards belonging to parent
    boards = Enum.filter(board_mapping, fn board -> Map.get(board, board_mapping_key) == parent.id end)
    # flatten preloaded board data onto board, remove struct and ecto meta
    boards = boards
    |> Enum.map(fn board ->
      # flatten needed boards data
      board = board
      |> Map.merge(board.board || %{})
      |> Map.merge(board.stats || %{})
      |> Map.merge(board.thread || %{})

      # delete unneeded properties
      board = board
      |> Map.delete(:board)
      |> Map.delete(:stats)
      |> Map.delete(:thread)
      |> Map.delete(:parent)
      |> Map.delete(:category)
      |> Map.delete(:__meta__)
      |> Map.delete(:__struct__)

      # handle deleted last post data
      if !!Map.get(board, :post_deleted) or !!Map.get(board, :user_deleted),
        do: board |> Map.put(:last_post_username, "deleted"),
        else: board
    end)
    # sort boards by view order within respective parent
    boards = boards |> Enum.sort_by(fn board -> board.view_order end)

    # iterate each child board, attempt to map nested children from board mapping
    boards = Enum.reduce(boards, [], fn board, acc ->
      board = process_children_from_board_mapping(:parent_id, board_mapping, :children, board)
      acc ++ [board]
    end)

    # remove ecto struct and meta from category map
    parent = Map.put(parent, child_key, boards) |> Map.delete(:__meta__) |> Map.delete(:__struct__)
  end
end
