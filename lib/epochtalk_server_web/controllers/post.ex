defmodule EpochtalkServerWeb.Controllers.Post do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Post` related API requests
  """
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.Helpers.Validate
  alias EpochtalkServerWeb.Helpers.ACL
  alias EpochtalkServerWeb.Helpers.Sanitize
  alias EpochtalkServerWeb.Helpers.Parse
  alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Models.Poll
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.BoardBan
  alias EpochtalkServer.Models.BoardMapping
  alias EpochtalkServer.Models.BoardModerator
  alias EpochtalkServer.Models.MetricRankMap
  alias EpochtalkServer.Models.Rank
  alias EpochtalkServer.Models.Trust
  alias EpochtalkServer.Models.UserActivity
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.UserIgnored
  alias EpochtalkServer.Models.WatchThread
  alias EpochtalkServer.Models.ThreadSubscription
  alias EpochtalkServer.Models.AutoModeration
  alias EpochtalkServer.Models.Mention

  @max_post_title_length 255

  @doc """
  Used to create posts
  """
  # TODO(akinsey): test cases on top of post creation
  # * Ensure thread subsciption emails are sent out and are deleted properly after sending
  # * Ensure user activity is updated properly
  # * Ensure user watches thread if preference is set after creation
  # * Ensure mentions and notifications are created
  def create(conn, attrs) do
    # Authorizations Checks
    with {:auth, user} <- {:auth, Guardian.Plug.current_resource(conn)},
         :ok <- ACL.allow!(conn, "posts.create"),
         # normally we use model changesets for validating POST requests parameters,
         # this is an exception to save us from doing excessive processing between here
         # and the creation of the post
         post_max_length <-
           Application.get_env(:epochtalk_server, :frontend_config)["post_max_length"],
         thread_id <- Validate.cast(attrs, "thread_id", :integer, required: true),
         _title <-
           Validate.cast(attrs, "title", :string, required: true, max: @max_post_title_length),
         _body <- Validate.cast(attrs, "body", :string, required: true, max: post_max_length),
         user_priority <- ACL.get_user_priority(conn),
         {:bypass_lock, true} <-
           {:bypass_lock, can_authed_user_bypass_thread_lock(user, thread_id)},
         {:is_active, true} <-
           {:is_active, User.is_active?(user.id)},
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_thread_id(thread_id, user_priority)},
         {:can_write, {:ok, true}} <-
           {:can_write, Board.get_write_access_by_thread_id(thread_id, user_priority)},
         {:board_banned, {:ok, false}} <-
           {:board_banned, BoardBan.is_banned_from_board(user, thread_id: thread_id)},
         attrs <- AutoModeration.moderate(user, attrs),
         attrs <- Mention.username_to_user_id(user, attrs),
         attrs <- Sanitize.html_and_entities_from_title(attrs["title"], attrs),
         attrs <- Sanitize.html_and_entities_from_body(attrs["body"], attrs),
         attrs <- Parse.markdown_within_body(attrs["body"], attrs),
         # TODO(akinsey): Implement the following for completion
         # Plugins
         # 1) Track IP (done)

         # Pre Processing

         # 1) clean post title (done)
         # 2) parse/clean post body
         # 3) handle uploaded images
         # 4) handle filtering out newbie images

         # Hooks
         # 1) Auto Moderation (pre) (done) (write tests)

         # 2) Update user Activity (post) (done) (write test)

         # 3) Mentions -> convert username to user id (pre) (done) (write tests)
         # 4) Mentions -> create mentions (post) (done) (write tests)
         # 5) Mentions -> correct text search vector after creating mentions (post) (done) (write tests)

         # 6) Thread Subscriptions -> Email Subscribers (post) (done) (write test)
         # 7) Thread Subscriptions -> Subscribe to Thread (post) (done) (write test)

         # Data Queries
         {:ok, post_data} <- Post.create(attrs, user.id) do
      # Create Mention notification
      Mention.handle_user_mention_creation(user, attrs, post_data)

      # Correct TSV due to mentions converting username to user id
      Mention.correct_text_search_vector(attrs)

      # Update user activity
      UserActivity.update_user_activity(user)

      # watch thread after post is created
      WatchThread.create(user, thread_id)

      # Email Thread Subscribers
      ThreadSubscription.email_subscribers(user, thread_id)

      # Subscribe to Thread (this will check user preferences)
      ThreadSubscription.create(user, thread_id)

      # render post json data
      render(conn, :create, %{post_data: post_data})
    else
      {:error, %Ecto.Changeset{} = cs} ->
        ErrorHelpers.render_json_error(conn, 400, cs)

      {:auth, nil} ->
        ErrorHelpers.render_json_error(conn, 400, "Not logged in, cannot create post")

      {:bypass_lock, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Thread is locked")

      {:is_active, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Account must be active to create posts")

      {:can_read, {:ok, false}} ->
        ErrorHelpers.render_json_error(conn, 403, "Unauthorized, you do not have permission")

      {:can_write, {:ok, false}} ->
        ErrorHelpers.render_json_error(conn, 403, "Unauthorized, you do not have permission")

      {:board_banned, {:ok, true}} ->
        ErrorHelpers.render_json_error(conn, 403, "Unauthorized, you are banned from this board")

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot create post")
    end
  end

  @doc """
  Used to retrieve `Posts` by `Thread`

  Test Cases:
  1) Authenticated vs Not Authenticated
  2) Thread with Poll vs no Poll
  3) Query with start position vs page
  4) Read/Write access test against user priority (postable/writable by on board)
  5) Base permission check
  6) Authorizations tests
  7) Board ban on authed user
  8) Board and Thread metadata is correct (ex: board.signature_disabled, thread.trust_visible)
  9) Ignored users posts are hidden properly
  10) Rank and activity are calculated for each post
  """
  # TODO(akinsey): Implement for completion
  # - parser
  def by_thread(conn, attrs) do
    # Parameter Validation
    with thread_id <- Validate.cast(attrs, "thread_id", :integer, required: true),
         page <- Validate.cast(attrs, "page", :integer, default: 1, min: 1),
         start <- Validate.cast(attrs, "start", :integer, min: 1),
         limit <- Validate.cast(attrs, "limit", :integer, default: 25, min: 1, max: 100),
         desc <- Validate.cast(attrs, "desc", :boolean, default: true),
         :ok <- Validate.mutually_exclusive!(attrs, ["page", "start"]),
         user <- Guardian.Plug.current_resource(conn),
         user_priority <- ACL.get_user_priority(conn),

         # Authorizations Checks
         :ok <- ACL.allow!(conn, "posts.byThread"),
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_thread_id(thread_id, user_priority)},
         view_deleted_posts <- can_authed_user_view_deleted_posts(user, thread_id),

         # Data Queries
         {:ok, write_access} <- Board.get_write_access_by_thread_id(thread_id, user_priority),
         {:ok, board_banned} <- BoardBan.is_banned_from_board(user, thread_id: thread_id),
         board_mapping <- BoardMapping.all(),
         board_moderators <- BoardModerator.all(),
         poll <- Poll.by_thread(thread_id),
         thread <- Thread.find(thread_id),
         posts <-
           Post.page_by_thread_id(thread_id, page,
             user: user,
             start: start,
             per_page: limit
           ),
         {:has_posts, true} <- {:has_posts, posts != []},

         # Hooks (Addtional related data)
         posts <- Trust.maybe_append_trust_stats_to_posts(posts, user),
         thread <- Trust.maybe_append_trust_visible_to_thread(thread, user),
         posts <- UserActivity.append_user_activity_to_posts(posts),
         posts <- UserIgnored.append_user_ignored_data_to_posts(posts, user),
         metric_rank_maps <- MetricRankMap.all_merged(),
         ranks <- Rank.all(),
         posts <- Mention.user_id_to_username(posts),
         {:ok, watching_thread} <- WatchThread.is_watching(user, thread_id) do
      render(conn, :by_thread, %{
        posts: posts,
        poll: poll,
        thread: thread,
        write_access: write_access && is_map(user) && !board_banned,
        board_banned: board_banned,
        user: user,
        user_priority: user_priority,
        board_mapping: board_mapping,
        board_moderators: board_moderators,
        page: page,
        start: start,
        limit: limit,
        desc: desc,
        metric_rank_maps: metric_rank_maps,
        ranks: ranks,
        watched: watching_thread,
        view_deleted_posts: view_deleted_posts
      })
    else
      {:error, :board_does_not_exist} ->
        ErrorHelpers.render_json_error(conn, 400, "Error, thread does not exist")

      {:can_read, {:ok, false}} ->
        ErrorHelpers.render_json_error(conn, 403, "Unauthorized, you do not have permission")

      {:has_posts, false} ->
        ErrorHelpers.render_json_error(conn, 404, "Error, requested posts not found in thread")

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot get posts by thread")
    end
  end

  ## === Private Helper Functions ===

  defp can_authed_user_view_deleted_posts(nil, _thread_id), do: false

  defp can_authed_user_view_deleted_posts(user, thread_id) do
    view_all = ACL.has_permission(user, "posts.byThread.bypass.viewDeletedPosts.admin")
    view_some = ACL.has_permission(user, "posts.byThread.bypass.viewDeletedPosts.mod")
    view_self_mod = ACL.has_permission(user, "posts.byThread.bypass.viewDeletedPosts.selfMod")
    view_priority = ACL.has_permission(user, "posts.byThread.bypass.viewDeletedPosts.priority")

    user_id = Map.get(user, :id)
    moderated_boards = BoardModerator.get_user_moderated_boards(user_id)

    cond do
      view_all or view_priority ->
        true

      view_some and moderated_boards != [] ->
        moderated_boards

      view_self_mod and moderated_boards == [] ->
        Thread.is_self_moderated_by_user(thread_id, user_id)

      true ->
        false
    end
  end

  defp can_authed_user_bypass_thread_lock(user, thread_id) do
    has_bypass = ACL.has_permission(user, "posts.create.bypass.locked.admin")
    thread_not_locked = !Thread.is_locked(thread_id)
    is_mod = BoardModerator.user_is_moderator_with_thread_id(thread_id, user.id)

    has_bypass or thread_not_locked or is_mod
  end
end
