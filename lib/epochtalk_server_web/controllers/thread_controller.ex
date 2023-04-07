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
  alias EpochtalkServer.Models.Post
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
  Used to create threads

  TODO(akinsey): Regex validation for slug, length check for strings, implement poll validation (use model validation)
  TODO(akinsey): implement polls
  TODO(akinsey): Post pre processing, image processing, hooks
  """
  def create(conn, attrs) do
    with locked <- Validate.cast(attrs, "locked", :boolean, default: false),
         sticky <- Validate.cast(attrs, "sticky", :boolean, default: false),
         moderated <- Validate.cast(attrs, "moderated", :boolean, default: false),
         title <- Validate.cast(attrs, "title", :string, required: true),
         slug <- Validate.cast(attrs, "slug", :string, required: true),
         body <- Validate.cast(attrs, "body", :string, required: true),
         board_id <- Validate.cast(attrs, "board_id", :integer, required: true),
         user <- Guardian.Plug.current_resource(conn),
         {:ok, thread} <- Thread.create(%{
           board_id: board_id,
           locked: locked,
           sticky: sticky,
           moderated: moderated,
           slug: slug
         }),
         {:ok, post} <- Post.create(%{
          thread_id: thread.id,
          user_id: user.id,
          content: %{title: title, body: body}
         }) do
      render(conn, "create.json", %{
        data: post
      })
    else
      _ -> ErrorHelpers.render_json_error(conn, 400, "Error, cannot create thread")
    end
  end

  @doc """
  Used to retrieve threads by board
  """
  def by_board(conn, attrs) do
    with board_id <- Validate.cast(attrs, "board_id", :integer, required: true),
         page <- Validate.cast(attrs, "page", :integer, default: 1),
         field <- Validate.cast(attrs, "field", :string, default: "updated_at"),
         limit <- Validate.cast(attrs, "limit", :integer, default: 25),
         desc <- Validate.cast(attrs, "desc", :boolean, default: true),
         user <- Guardian.Plug.current_resource(conn),
         user_priority <- ACL.get_user_priority(conn),
         :ok <- ACL.allow!(conn, "threads.byBoard"),
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_id(board_id, user_priority)},
         {:ok, write_access} <- Board.get_write_access_by_id(board_id, user_priority),
         {:ok, board_banned} <- BoardBan.is_banned_from_board(user, board_id: board_id),
         board_mapping <- BoardMapping.all(),
         board_moderators <- BoardModerator.all(),
         threads <-
           Thread.page_by_board_id(board_id, page,
             user: user,
             per_page: limit,
             field: field,
             desc: desc
           ) do
      render(conn, "by_board.json", %{
        threads: threads,
        write_access: write_access && is_map(user) && !board_banned,
        board_banned: board_banned,
        user: user,
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
      {:error, :board_does_not_exist} ->
        ErrorHelpers.render_json_error(conn, 400, "Error, board does not exist")

      {:can_read, {:ok, false}} ->
        ErrorHelpers.render_json_error(conn, 403, "Unauthorized, you do not have permission")

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot get threads by board")
    end
  end
end
