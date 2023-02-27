defmodule EpochtalkServerWeb.ThreadView do
  use EpochtalkServerWeb, :view

  alias EpochtalkServerWeb.BoardView
  @moduledoc """
  Renders and formats `Thread` data, in JSON format for frontend
  """

  @doc """
  Renders whatever data it is passed when template not found. Data pass through
  for rendering misc responses (ex: {found: true} or {success: true})
  ## Example
      iex> EpochtalkServerWeb.ThreadView.render("DoesNotExist.json", data: %{anything: "abc"})
      %{anything: "abc"}
      iex> EpochtalkServerWeb.ThreadView.render("DoesNotExist.json", data: %{success: true})
      %{success: true}
  """
  def template_not_found(_template, %{data: data}), do: data

  @doc """
  Renders recent `Thread` data.
  """
  def render("recent.json", %{
        threads: threads
      }) do
    threads
    |> Enum.map(fn thread ->
      %{id: thread.id, slug: thread.slug, updated_at: thread.updated_at}
    end)
  end

  @doc """
  Renders `Board` for find query.
  """
  def render("by_board.json", %{
        board_moderators: board_moderators,
        board_mapping: board_mapping,
        board_id: board_id,
        user_priority: user_priority,
        write_access: write_access,
        board_banned: board_banned,
        page: page,
        field: field,
        limit: limit,
        desc: desc
      }) do
    board = BoardView.format_board_data_for_find(board_moderators, board_mapping, board_id, user_priority)
    result = %{
      board: board,
      write_access: write_access,
      page: page,
      field: field,
      limit: limit,
      desc: desc,
    }
    if board_banned, do: Map.put(result, :board_banned, board_banned), else: result
  end
end
