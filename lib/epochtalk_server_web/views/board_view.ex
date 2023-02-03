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
    categories = Enum.reduce(categories, [], fn category, acc ->
      boards = Enum.filter(board_mapping, fn board -> board.category_id == category.id end)
      |> Enum.map(fn board -> Map.merge(board.board, board.stats || %{}) |> Map.merge(board.thread || %{}) end)
      category = Map.put(category, :boards, boards)
      acc ++ [category]
    end)
    IO.inspect(categories)
    %{}
  end
end
