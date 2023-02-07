defmodule EpochtalkServerWeb.BoardController do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Board` related API requests
  """
  alias EpochtalkServer.Auth.Guardian
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
    with page <- Validate.cast(attrs, "page", :integer, min: 1, default: 1),
         limit <- Validate.cast(attrs, "limit", :integer, min: 1, max: 100, default: 5),
         stripped <- Validate.cast(attrs, "stripped", :boolean, default: false),
         user <- Guardian.Plug.current_resource(conn),
         priority <- ACL.get_user_priority(user) do
      opts = %{page: page, limit: limit, stripped: stripped, priority: priority}
      IO.inspect opts
      board_mapping = BoardMapping.all(stripped: stripped)
      board_moderators = BoardModerator.all()
      categories = Category.all()
      render(conn, "by_category.json", %{
        categories: categories,
        board_moderators: board_moderators,
        board_mapping: board_mapping
      })
    else
      _ -> ErrorHelpers.render_json_error(conn, 400, "Error, cannot fetch boards")
    end
  end
end
