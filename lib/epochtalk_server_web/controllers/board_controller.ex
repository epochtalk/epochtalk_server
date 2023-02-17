defmodule EpochtalkServerWeb.BoardController do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Board` related API requests
  """
  alias EpochtalkServer.Models.BoardModerator
  alias EpochtalkServer.Models.BoardMapping
  alias EpochtalkServer.Models.Category
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.Helpers.Validate
  alias EpochtalkServerWeb.Helpers.ACL

  @doc """
  Used to retrieve categorized boards
  """
  def by_category(conn, attrs) do
    with stripped <- Validate.cast(attrs, "stripped", :boolean, default: false),
         user_priority <- ACL.get_user_priority(conn),
         board_mapping <- BoardMapping.all(stripped: stripped),
         board_moderators <- BoardModerator.all(),
         categories <- Category.all() do
      render(conn, "by_category.json", %{
        categories: categories,
        board_moderators: board_moderators,
        board_mapping: board_mapping,
        user_priority: user_priority
      })
    else
      _ -> ErrorHelpers.render_json_error(conn, 400, "Error, cannot fetch boards")
    end
  end

  @doc """
  Used to find a specific board
  """
  def find(conn, attrs) do
    with id <- Validate.cast(attrs, "id", :integer, required: true),
         user_priority <- ACL.get_user_priority(conn),
         board_mapping <- BoardMapping.all(),
         board_moderators <- BoardModerator.all(),
         {:board, [_board]} <-
           {:board, Enum.filter(board_mapping, fn bm -> bm.board_id == id end)} do
      render(conn, "find.json", %{
        board_moderators: board_moderators,
        board_mapping: board_mapping,
        board_id: id,
        user_priority: user_priority
      })
    else
      {:board, []} -> ErrorHelpers.render_json_error(conn, 400, "Error, board does not exist")
      _ -> ErrorHelpers.render_json_error(conn, 400, "Error, cannot fetch boards")
    end
  end
end
