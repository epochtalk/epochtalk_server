defmodule EpochtalkServerWeb.Controllers.Thread do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Thread` related API requests
  """
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServer.Mailer
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.Helpers.Validate
  alias EpochtalkServerWeb.Helpers.ACL
  alias EpochtalkServerWeb.Helpers.Sanitize
  alias EpochtalkServerWeb.Helpers.Parse
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.BoardBan
  alias EpochtalkServer.Models.BoardMapping
  alias EpochtalkServer.Models.BoardModerator
  alias EpochtalkServer.Models.UserThreadView
  alias EpochtalkServer.Models.MetadataThread
  alias EpochtalkServer.Models.ModerationLog
  alias EpochtalkServer.Models.WatchThread
  alias EpochtalkServer.Models.WatchBoard
  alias EpochtalkServer.Models.AutoModeration
  alias EpochtalkServer.Models.UserActivity
  alias EpochtalkServer.Models.ThreadSubscription
  alias EpochtalkServer.Models.Mention

  @doc """
  Used to retrieve recent threads
  """
  def recent(conn, _attrs) do
    with user <- Guardian.Plug.current_resource(conn),
         user_priority <- ACL.get_user_priority(conn),
         threads <- Thread.recent(user, user_priority) do
      render(conn, :recent, %{threads: threads})
    end
  end

  @doc """
  Used to create threads
  """
  # TODO(akinsey): Post pre processing, authorizations, image processing, hooks. Things to consider:
  # - does html sanitizer need to run on the front end too
  # - how do we run the same parser/sanitizer on the elixir back end as the node frontend
  # - does createImageReferences need to be called here? was this missing from the old code?
  def create(conn, attrs) do
    # authorization checks
    with :ok <- ACL.allow!(conn, "threads.create"),
         board_id <- Validate.cast(attrs, "board_id", :integer, required: true),
         {:auth, %{} = user} <- {:auth, Guardian.Plug.current_resource(conn)},
         user_priority <- ACL.get_user_priority(conn),
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_id(board_id, user_priority)},
         {:can_write, {:ok, true}} <-
           {:can_write, Board.get_write_access_by_id(board_id, user_priority)},
         {:board_banned, {:ok, false}} <-
           {:board_banned, BoardBan.banned_from_board?(user, board_id: board_id)},
         {:is_active, true} <-
           {:is_active, User.is_active?(user.id)},
         {:allows_self_mod, true} <-
           {:allows_self_mod, Board.allows_self_moderation?(board_id, attrs["moderated"])},
         {:user_can_moderate, true} <-
           {:user_can_moderate, handle_check_user_can_moderate(user, attrs["moderated"])},
         # pre processing

         # pre/parallel hooks
         attrs <- AutoModeration.moderate(user, attrs),
         attrs <- Mention.username_to_user_id(user, attrs),
         attrs <- Sanitize.html_and_entities_from_title(attrs),
         attrs <- Sanitize.html_and_entities_from_body(attrs),
         attrs <- Parse.markdown_within_body(attrs),
         # thread creation
         {:ok, thread_data} <- Thread.create(attrs, user) do
      # post hooks
      post = Map.get(thread_data, :post)

      # Create Mention notification
      Mention.handle_user_mention_creation(user, attrs, post)

      # Correct TSV due to mentions converting username to user id,
      # append post id to attrs since this is thread creation
      Mention.correct_text_search_vector(attrs |> Map.put("id", post.id))

      # Update user activity
      UserActivity.update_user_activity(user)

      # Subscribe to Thread (this will check user preferences)
      ThreadSubscription.create(user, post.thread_id)

      # TODO(akinsey): Implement the following for completion
      # Authorizations
      # 1) Check base permissions (done)
      # 2) Check can read board (done)
      # 3) Check can write board (done)
      # 4) Is requester active (done)
      # 5) check board allows self mod (done)
      # 6) check user not banned from board (done)
      # 7) poll authorization (Poll creation should handle this? Yes.)
      #   - poll creatable permissions check (done in Thread model in handle poll creation)
      #   - poll validate max answers (done in Poll changeset)
      #   - poll validate display mode (done in Poll changeset)
      # 8) can user moderate this thread (done)

      # Pre Processing

      # 1) clean post
      # 2) parse post
      # 3) handle uploaded images
      # 4) handle filtering out newbie images

      # Hooks
      # 1) Auto Moderation moderate (pre) (done)

      # 2) Update user Activity (post) (note: this was missing in old code) (done)

      # 3) Mentions -> convert username to user id (pre) (done)
      # 4) Mentions -> create mentions (post) (done)
      # 5) Mentions -> correct text search vector after creating mentions (post) (done)

      # 6) Thread Subscriptions -> Subscribe to Thread (post) (done)
      render(conn, :create, %{thread_data: thread_data})
    else
      {:error, %Ecto.Changeset{} = cs} ->
        ErrorHelpers.render_json_error(conn, 400, cs)

      {:can_read, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to read"
        )

      {:can_write, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to write"
        )

      {:allows_self_mod, false} ->
        ErrorHelpers.render_json_error(
          conn,
          400,
          "This board does not allow self moderated threads"
        )

      {:is_active, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Account must be active to create threads")

      {:auth, nil} ->
        ErrorHelpers.render_json_error(conn, 400, "Not logged in, cannot create thread")

      {:board_banned, {:ok, true}} ->
        ErrorHelpers.render_json_error(conn, 403, "Unauthorized, you are banned from this board")

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
         {:ok, board_banned} <- BoardBan.banned_from_board?(user, board_id: board_id),
         {:ok, watching_board} <- WatchBoard.user_is_watching(user, board_id),
         board_mapping <- BoardMapping.all(),
         board_moderators <- BoardModerator.all(),
         threads <-
           Thread.page_by_board_id(board_id, page,
             user: user,
             per_page: limit,
             field: field,
             desc: desc
           ),
         {:has_threads, true} <- {:has_threads, threads.normal != [] || threads.sticky != []} do
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

      {:board_banned, {:ok, true}} ->
        ErrorHelpers.render_json_error(conn, 403, "Unauthorized, you are banned from this board")

      {:has_threads, false} ->
        ErrorHelpers.render_json_error(conn, 404, "Error, requested threads not found in board")

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot get threads by board")
    end
  end

  @doc """
  Used to retrieve `Threads` for a `User` by username
  """
  def by_username(conn, attrs) do
    # Parameter Validation
    with username <- attrs["username"],
         page <- Validate.cast(attrs, "page", :integer, default: 1, min: 1),
         limit <- Validate.cast(attrs, "limit", :integer, default: 25, min: 1, max: 100),
         desc <- Validate.cast(attrs, "desc", :boolean, default: true),
         user <- Guardian.Plug.current_resource(conn),
         priority <- ACL.get_user_priority(conn),
         [lookup_user] <- User.ids_from_usernames([username]),

         # Authorizations Checks (Same permission as post page by user)
         :ok <- ACL.allow!(conn, "posts.pageByUser"),
         {:user_not_deleted, user_not_deleted} <-
           {:user_not_deleted, User.is_active?(lookup_user.id)},
         {:has_deleted_override, has_deleted_override} <-
           {:has_deleted_override,
            ACL.has_permission(conn, "posts.pageFirstPostByUser.bypass.viewDeletedUsers")},
         {:view_deleted_users, true} <-
           {:view_deleted_users, user_not_deleted || has_deleted_override},
         view_deleted_threads <-
           EpochtalkServerWeb.Controllers.Post.can_authed_user_view_deleted_posts_by_username(
             user
           ),
         threads <-
           Thread.page_by_username(username, priority, page,
             per_page: limit + 1,
             desc: desc
           ) do
      render(conn, :by_username, %{
        threads: threads,
        user: user,
        priority: priority,
        view_deleted_threads: view_deleted_threads,
        limit: limit,
        desc: desc,
        page: page
      })
    else
      {:view_deleted_users, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Account not found")

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot get threads by username")
    end
  end

  @doc """
  Used to watch `Thread`
  """
  def watch(conn, attrs) do
    with user <- Guardian.Plug.current_resource(conn),
         thread_id <- Validate.cast(attrs, "thread_id", :integer, required: true),
         :ok <- ACL.allow!(conn, "watchlist.watchThread"),
         user_priority <- ACL.get_user_priority(conn),
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_thread_id(thread_id, user_priority)},
         {:is_active, true} <-
           {:is_active, User.is_active?(user.id)},
         {:ok, watch_thread} <- WatchThread.create(user, thread_id) do
      render(conn, :watch, thread: watch_thread)
    else
      {:can_read, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to read"
        )

      {:is_active, false} ->
        ErrorHelpers.render_json_error(
          conn,
          400,
          "Account must be active to watch thread"
        )

      {:error, data} ->
        ErrorHelpers.render_json_error(conn, 400, data)

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot watch thread")
    end
  end

  @doc """
  Used to unwatch `Thread`
  """
  def unwatch(conn, attrs) do
    with user <- Guardian.Plug.current_resource(conn),
         thread_id <- Validate.cast(attrs, "thread_id", :integer, required: true),
         :ok <- ACL.allow!(conn, "watchlist.unwatchThread"),
         user_priority <- ACL.get_user_priority(conn),
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_thread_id(thread_id, user_priority)},
         {:is_active, true} <-
           {:is_active, User.is_active?(user.id)},
         {1, nil} <- WatchThread.delete(user, thread_id) do
      render(conn, :watch, thread: %{thread_id: thread_id, user_id: user.id})
    else
      {:can_read, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to read"
        )

      {:is_active, false} ->
        ErrorHelpers.render_json_error(
          conn,
          400,
          "Account must be active to unwatch thread"
        )

      {:error, data} ->
        ErrorHelpers.render_json_error(conn, 400, data)

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot unwatch thread")
    end
  end

  @doc """
  Used to lock `Thread`
  """
  def lock(conn, attrs) do
    with user <- Guardian.Plug.current_resource(conn),
         thread_id <- Validate.cast(attrs, "thread_id", :integer, required: true),
         locked <- Validate.cast(attrs, "locked", :boolean, required: true),
         :ok <- ACL.allow!(conn, "threads.lock"),
         user_priority <- ACL.get_user_priority(conn),
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_thread_id(thread_id, user_priority)},
         {:can_write, {:ok, true}} <-
           {:can_write, Board.get_write_access_by_thread_id(thread_id, user_priority)},
         {:is_active, true} <-
           {:is_active, User.is_active?(user.id)},
         {:board_banned, {:ok, false}} <-
           {:board_banned, BoardBan.banned_from_board?(user, thread_id: thread_id)},
         {:bypass_thread_owner, true} <-
           {:bypass_thread_owner, can_authed_user_bypass_owner_on_thread_lock(user, thread_id)},
         {1, nil} <- Thread.set_locked(thread_id, locked) do
      render(conn, :lock, thread: %{thread_id: thread_id, locked: locked})
    else
      {:can_read, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to read"
        )

      {:can_write, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to write"
        )

      {:bypass_thread_owner, false} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to modify the lock on another user's thread"
        )

      {:board_banned, {:ok, true}} ->
        ErrorHelpers.render_json_error(conn, 403, "Unauthorized, you are banned from this board")

      {:is_active, false} ->
        ErrorHelpers.render_json_error(
          conn,
          400,
          "Account must be active to modify lock on thread"
        )

      {:error, data} ->
        ErrorHelpers.render_json_error(conn, 400, data)

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot lock thread")
    end
  end

  @doc """
  Used to sticky `Thread`
  """
  def sticky(conn, attrs) do
    with user <- Guardian.Plug.current_resource(conn),
         thread_id <- Validate.cast(attrs, "thread_id", :integer, required: true),
         sticky <- Validate.cast(attrs, "sticky", :boolean, required: true),
         :ok <- ACL.allow!(conn, "threads.sticky"),
         user_priority <- ACL.get_user_priority(conn),
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_thread_id(thread_id, user_priority)},
         {:can_write, {:ok, true}} <-
           {:can_write, Board.get_write_access_by_thread_id(thread_id, user_priority)},
         {:is_active, true} <-
           {:is_active, User.is_active?(user.id)},
         {:board_banned, {:ok, false}} <-
           {:board_banned, BoardBan.banned_from_board?(user, thread_id: thread_id)},
         {:bypass_thread_owner, true} <-
           {:bypass_thread_owner, can_authed_user_bypass_owner_on_thread_sticky(user, thread_id)},
         {1, nil} <- Thread.set_sticky(thread_id, sticky) do
      render(conn, :sticky, thread: %{thread_id: thread_id, sticky: sticky})
    else
      {:can_read, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to read"
        )

      {:can_write, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to write"
        )

      {:bypass_thread_owner, false} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to modify another user's thread"
        )

      {:board_banned, {:ok, true}} ->
        ErrorHelpers.render_json_error(conn, 403, "Unauthorized, you are banned from this board")

      {:is_active, false} ->
        ErrorHelpers.render_json_error(
          conn,
          400,
          "Account must be active to modify sticky on thread"
        )

      {:error, data} ->
        ErrorHelpers.render_json_error(conn, 400, data)

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot sticky thread")
    end
  end

  @doc """
  Used to purge `Thread`
  """
  def purge(conn, attrs) do
    with user <- Guardian.Plug.current_resource(conn),
         thread_id <- Validate.cast(attrs, "thread_id", :integer, required: true),
         :ok <- ACL.allow!(conn, "threads.purge"),
         user_priority <- ACL.get_user_priority(conn),
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_thread_id(thread_id, user_priority)},
         {:can_write, {:ok, true}} <-
           {:can_write, Board.get_write_access_by_thread_id(thread_id, user_priority)},
         {:is_active, true} <-
           {:is_active, User.is_active?(user.id)},
         {:board_banned, {:ok, false}} <-
           {:board_banned, BoardBan.banned_from_board?(user, thread_id: thread_id)},
         {:bypass_thread_owner, true} <-
           {:bypass_thread_owner, can_authed_user_bypass_owner_on_thread_purge(user, thread_id)},
         {:ok, thread} <- Thread.purge(thread_id) do
      poster_data = User.email_by_id_list(thread.poster_ids)

      # Email thread owner and subscribers
      Enum.each(poster_data, fn %{user_id: user_id, email: email, username: username} ->
        action = if thread.user_id == user_id, do: "created", else: "participated in"

        Mailer.send_thread_purge(%{
          email: email,
          title: thread.title,
          username: username,
          action: action,
          mod_username: user.username
        })
      end)

      # parse moderator's ip, remove ipv6 prefix if present
      mod_ip_str =
        conn.remote_ip
        |> :inet_parse.ntoa()
        |> to_string
        |> String.replace("::ffff:", "")

      {:ok, _moderation_log} =
        ModerationLog.create(%{
          mod: %{username: user.username, id: user.id, ip: mod_ip_str},
          action: %{
            api_url: "/api/threads/#{thread_id}",
            api_method: "delete",
            type: "threads.purge",
            obj: thread
          }
        })

      render(conn, :purge, thread: thread)
    else
      {:can_read, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to read"
        )

      {:can_write, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to write"
        )

      {:bypass_thread_owner, false} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to modify another user's thread"
        )

      {:board_banned, {:ok, true}} ->
        ErrorHelpers.render_json_error(conn, 403, "Unauthorized, you are banned from this board")

      {:is_active, false} ->
        ErrorHelpers.render_json_error(
          conn,
          400,
          "Account must be active to modify purge on thread"
        )

      {:error, data} ->
        ErrorHelpers.render_json_error(conn, 400, data)

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot purge thread")
    end
  end

  @doc """
  Used to move a `Thread`
  """
  def move(conn, attrs) do
    with user <- Guardian.Plug.current_resource(conn),
         thread_id <- Validate.cast(attrs, "thread_id", :integer, required: true),
         new_board_id <- Validate.cast(attrs, "new_board_id", :integer, required: true),
         :ok <- ACL.allow!(conn, "threads.move"),
         user_priority <- ACL.get_user_priority(conn),
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_thread_id(thread_id, user_priority)},
         {:can_write, {:ok, true}} <-
           {:can_write, Board.get_write_access_by_thread_id(thread_id, user_priority)},
         {:is_active, true} <-
           {:is_active, User.is_active?(user.id)},
         {:board_banned, {:ok, false}} <-
           {:board_banned, BoardBan.banned_from_board?(user, thread_id: thread_id)},
         {:bypass_thread_owner, true} <-
           {:bypass_thread_owner, can_authed_user_bypass_owner_on_thread_move(user, thread_id)},
         {:ok, old_board_data} <- Thread.move(thread_id, new_board_id) do
      render(conn, :move, old_board_data: old_board_data)
    else
      {:can_read, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to read"
        )

      {:can_write, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to write"
        )

      {:bypass_thread_owner, false} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to move another user's thread"
        )

      {:board_banned, {:ok, true}} ->
        ErrorHelpers.render_json_error(conn, 403, "Unauthorized, you are banned from this board")

      {:is_active, false} ->
        ErrorHelpers.render_json_error(
          conn,
          400,
          "Account must be active to move thread"
        )

      {:error, data} ->
        ErrorHelpers.render_json_error(conn, 400, data)

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot move thread")
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
    viewer_ip =
      conn.remote_ip
      |> :inet_parse.ntoa()
      |> to_string
      |> String.replace("::ffff:", "")

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

  # === Private Authorization Helpers Functions ===

  defp handle_check_user_can_moderate(user, moderated) do
    if moderated,
      do: :ok == ACL.allow!(user, "threads.moderated"),
      else: true
  end

  defp can_authed_user_bypass_owner_on_thread_purge(user, thread_id) do
    post = Thread.get_first_post_data_by_id(thread_id)

    ACL.bypass_post_owner(
      user,
      post,
      "threads.purge",
      "owner",
      false,
      true,
      true
    )
  end

  defp can_authed_user_bypass_owner_on_thread_sticky(user, thread_id) do
    post = Thread.get_first_post_data_by_id(thread_id)

    ACL.bypass_post_owner(
      user,
      post,
      "threads.sticky",
      "owner",
      false,
      true,
      true
    )
  end

  defp can_authed_user_bypass_owner_on_thread_lock(user, thread_id) do
    post = Thread.get_first_post_data_by_id(thread_id)

    ACL.bypass_post_owner(
      user,
      post,
      "threads.lock",
      "owner",
      post.user_id == user.id,
      true,
      true
    )
  end

  defp can_authed_user_bypass_owner_on_thread_move(user, thread_id) do
    post = Thread.get_first_post_data_by_id(thread_id)

    ACL.bypass_post_owner(
      user,
      post,
      "threads.move",
      "owner",
      false,
      true,
      true
    )
  end
end
