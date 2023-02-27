defmodule EpochtalkServerWeb.ThreadController do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Thread` related API requests
  """
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.Helpers.Validate
  alias EpochtalkServerWeb.Helpers.ACL
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.BoardBan
  alias EpochtalkServer.Models.BoardMapping
  alias EpochtalkServer.Models.BoardModerator

  @doc """
  Used to retrieve recent threads

  TODO(akinsey): come back to this after implementing thread and post create
  """
  def recent(conn, attrs) do
    with limit <- Validate.cast(attrs, "limit", :integer, default: 5),
         user <- Guardian.Plug.current_resource(conn),
         user_priority <- ACL.get_user_priority(conn),
         threads <- Thread.recent(user, user_priority, limit: limit) do
      render(conn, "recent.json", %{
        threads: threads
      })
    else
      _ -> ErrorHelpers.render_json_error(conn, 400, "Error, cannot fetch recent threads")
    end
  end

  @doc """
  Used to retrieve threads by board

  TODO(akinsey): ensure all board data is present (watched, stick_thread_count),
  implement thread paging
  """
  def by_board(conn, attrs) do
    with board_id <- Validate.cast(attrs, "board_id", :integer, required: true),
         page <- Validate.cast(attrs, "page", :integer, default: 1),
         field <- Validate.cast(attrs, "field", :string, default: "updated_at"),
         limit <- Validate.cast(attrs, "limit", :integer, default: 25),
         desc <- Validate.cast(attrs, "desc", :boolean, default: true),
         {:auth, user} <- {:auth, Guardian.Plug.current_resource(conn)},
         user_priority <- ACL.get_user_priority(conn),
         {:ok, write_access} <- Board.get_write_access_by_id(board_id, user_priority),
         {:ok, board_banned} <- BoardBan.is_banned_from_board(user, board_id: board_id),
         board_mapping <- BoardMapping.all(),
         board_moderators <- BoardModerator.all() do
      render(conn, "by_board.json", %{
        write_access: !!(user && write_access && !board_banned),
        board_banned: board_banned,
        user_priority: user_priority,
        board_id: board_id,
        board_mapping: board_mapping,
        board_moderators: board_moderators,
        page: page,
        field: field,
        limit: limit,
        desc: desc
      })
    else
      {:error, :board_does_not_exist} -> ErrorHelpers.render_json_error(conn, 400, "Error, board does not exist")
      _ -> ErrorHelpers.render_json_error(conn, 400, "Error, cannot get threads by board")
    end
  end
end
