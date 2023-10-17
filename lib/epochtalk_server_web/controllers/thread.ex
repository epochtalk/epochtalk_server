defmodule EpochtalkServerWeb.Controllers.Thread do
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
  alias EpochtalkServer.Models.UserThreadView
  alias EpochtalkServer.Models.MetadataThread
  alias EpochtalkServer.Models.WatchBoard

  @doc """
  Used to retrieve recent threads
  """
  # TODO(akinsey): come back to this after implementing thread and post create
  def recent(conn, attrs) do
    with limit <- Validate.cast(attrs, "limit", :integer, default: 5),
         user <- Guardian.Plug.current_resource(conn),
         user_priority <- ACL.get_user_priority(conn),
         threads <- Thread.recent(user, user_priority, limit: limit) do
      render(conn, :recent, %{threads: threads})
    else
      _ -> ErrorHelpers.render_json_error(conn, 400, "Error, cannot fetch recent threads")
    end
  end

  @doc """
  Used to create threads
  """
  # TODO(akinsey): Post pre processing, authorizations, image processing, hooks. Things to consider:
  # - does html sanitizer need to run on the front end too
  # - how do we run the same parser/sanitizer on the elixir back end as the node frontend
  # - processing mentions
  # - does createImageReferences need to be called here? was this missing from the old code?
  # - does updateUserActivity need to be called here? was this missing from the old code?
  def create(conn, attrs) do
    # authorization checks
    with :ok <- ACL.allow!(conn, "threads.create"),
         board_id <- Validate.cast(attrs, "board_id", :integer, required: true),
         {:auth, user} <- {:auth, Guardian.Plug.current_resource(conn)},
         user_priority <- ACL.get_user_priority(conn),
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_id(board_id, user_priority)},
         {:can_write, {:ok, true}} <-
           {:can_write, Board.get_write_access_by_id(board_id, user_priority)},

         # thread creation
         {:ok, thread_data} <- Thread.create(attrs, user.id) do
      # TODO(akinsey): Implement the following for completion
      # Authorizations
      # 1) Check base permissions (done)
      # 2) Check can read board (done)
      # 3) Check can write board (done)
      # 4) Is requester active
      # 5) check board allows self mod
      # 6) check user not banned from board
      # 7) poll authorization (Poll creation should handle this?)
      #   - poll creatable permissions check (Poll creation should handle this?)
      #   - poll validate max answers (Poll creation should handle this?)
      #   - poll validate display mode (Poll creation should handle this?)
      # 8) can user moderate this thread

      # Pre Processing

      # 1) clean post (html_sanitize_ex)
      # 2) parse post
      # 3) handle uploaded images
      # 4) handle filtering out newbie images

      # Hooks
      # 1) Auto Moderation moderate (pre)

      # 2) Update user Activity (post) (note: this was missing in old code)

      # 3) Mentions -> convert username to user id (pre)
      # 4) Mentions -> create mentions (post)
      # 5) Mentions -> correct text search vector after creating mentions (post)

      # 6) Thread Subscriptions -> Subscribe to Thread (post)
      render(conn, :create, %{thread_data: thread_data})
    else
      {:error, %Ecto.Changeset{} = cs} ->
        ErrorHelpers.render_json_error(conn, 400, cs)

      {:can_read, {:ok, false}} ->
        ErrorHelpers.render_json_error(conn, 403, "Unauthorized, you do not have permission")

      {:can_write, {:ok, false}} ->
        ErrorHelpers.render_json_error(conn, 403, "Unauthorized, you do not have permission")

      {:auth, nil} ->
        ErrorHelpers.render_json_error(conn, 400, "Not logged in, cannot create thread")

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot create thread")
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
         {:ok, watching_board} <- WatchBoard.is_watching(user, board_id),
         board_mapping <- BoardMapping.all(),
         board_moderators <- BoardModerator.all(),
         threads <-
           Thread.page_by_board_id(board_id, page,
             user: user,
             per_page: limit,
             field: field,
             desc: desc
           ) do
      render(conn, :by_board, %{
        threads: threads,
        write_access: write_access && is_map(user) && !board_banned,
        board_banned: board_banned,
        user: user,
        user_priority: user_priority,
        board_id: board_id,
        board_mapping: board_mapping,
        board_moderators: board_moderators,
        watched: watching_board,
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

      {:can_read, {:error, :board_does_not_exist}} ->
        ErrorHelpers.render_json_error(conn, 400, "Read error, board does not exist")

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot get threads by board")
    end
  end

  @doc """
  Used to convert `Thread` slug to id
  """
  def slug_to_id(conn, attrs) do
    with slug <- Validate.cast(attrs, "slug", :string, required: true),
         {:ok, id} <- Thread.slug_to_id(slug) do
      render(conn, :slug_to_id, id: id)
    else
      {:error, :thread_does_not_exist} ->
        ErrorHelpers.render_json_error(
          conn,
          400,
          "Error, cannot convert slug, thread does not exist"
        )

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot convert thread slug to id")
    end
  end

  @doc """
  Used to mark `Thread` as viewed for a specific user
  """
  def viewed(conn, attrs) do
    with thread_id <- Validate.cast(attrs, "id", :integer, required: true),
         :ok <- ACL.allow!(conn, "threads.viewed"),
         user <- Guardian.Plug.current_resource(conn),
         user_priority <- ACL.get_user_priority(conn),
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_thread_id(thread_id, user_priority)},
         new_viewer_id <- maybe_update_thread_view_count(conn, thread_id),
         {:ok, _user_thread_view} <- update_user_thread_view_count(user, thread_id) do
      conn =
        if new_viewer_id, do: put_resp_header(conn, "epoch-viewer", new_viewer_id), else: conn

      conn
      |> send_resp(200, [])
      |> halt()
    else
      {:error, :board_does_not_exist} ->
        ErrorHelpers.render_json_error(
          conn,
          400,
          "Error, cannot mark thread viewed, parent board does not exist"
        )

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot mark thread viewed")
    end
  end

  ## === Private Helper Functions ===

  defp maybe_update_thread_view_count(conn, thread_id) do
    viewer_id =
      case Plug.Conn.get_req_header(conn, "epoch-viewer") do
        [] -> ""
        [viewer_id] -> viewer_id
      end

    new_viewer_id = if viewer_id == "", do: Ecto.UUID.generate(), else: nil
    viewer_id = if viewer_id == "", do: new_viewer_id, else: viewer_id
    viewer_id_key = viewer_id <> Integer.to_string(thread_id)

    if handle_cooloff(viewer_id_key, viewer_id, thread_id) == {:ok, "OK"},
      do: check_view_ip(conn, thread_id)

    new_viewer_id
  end

  defp handle_cooloff(key, id, thread_id, increment \\ false) do
    case check_view_key(key) do
      # data exists and in cool off, do nothing
      %{exists: true, cooloff: true} ->
        nil

      # data exists and not in cooloff, increment thread view count
      %{exists: true, cooloff: false} ->
        MetadataThread.increment_view_count(thread_id)

      # data doesn't exist, save this ip/thread key to redis
      %{exists: false} ->
        if increment, do: MetadataThread.increment_view_count(thread_id)
        update_thread_view_flag_for_viewer(id, thread_id)
    end
  end

  defp update_thread_view_flag_for_viewer(key),
    do: Redix.command(:redix, ["SET", key, NaiveDateTime.utc_now()])

  defp update_thread_view_flag_for_viewer(viewer, thread_id),
    do: update_thread_view_flag_for_viewer(viewer <> Integer.to_string(thread_id))

  defp get_thread_view_flag_for_viewer(key), do: Redix.command!(:redix, ["GET", key])

  defp check_view_ip(conn, thread_id) do
    # convert ip tuple into string
    viewer_ip = conn.remote_ip |> :inet_parse.ntoa() |> to_string
    viewer_ip_key = viewer_ip <> Integer.to_string(thread_id)
    handle_cooloff(viewer_ip_key, viewer_ip, thread_id, true)
  end

  defp check_view_key(key) do
    if stored_time = get_thread_view_flag_for_viewer(key) do
      stored_time_naive = NaiveDateTime.from_iso8601!(stored_time)
      time_elapsed = NaiveDateTime.diff(NaiveDateTime.utc_now(), stored_time_naive, :second)
      one_hour_elapsed = time_elapsed > 60 * 60
      if one_hour_elapsed, do: update_thread_view_flag_for_viewer(key)
      %{exists: true, cooloff: !one_hour_elapsed}
    else
      %{exists: false}
    end
  end

  defp update_user_thread_view_count(nil, _thread_id), do: {:ok, nil}

  defp update_user_thread_view_count(user, thread_id),
    do: UserThreadView.upsert(user.id, thread_id)
end
