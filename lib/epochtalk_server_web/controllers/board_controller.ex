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
end
