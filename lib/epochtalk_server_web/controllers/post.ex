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
    with {:auth, %{} = user} <- {:auth, Guardian.Plug.current_resource(conn)},
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
           {:bypass_lock, can_authed_user_bypass_thread_lock_on_post_create(user, thread_id)},
         {:is_active, true} <-
           {:is_active, User.is_active?(user.id)},
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_thread_id(thread_id, user_priority)},
         {:can_write, {:ok, true}} <-
           {:can_write, Board.get_write_access_by_thread_id(thread_id, user_priority)},
         {:board_banned, {:ok, false}} <-
           {:board_banned, BoardBan.banned_from_board?(user, thread_id: thread_id)},
         attrs <- AutoModeration.moderate(user, attrs),
         attrs <- Mention.username_to_user_id(user, attrs),
         attrs <- Sanitize.html_and_entities_from_title(attrs),
         attrs <- Sanitize.html_and_entities_from_body(attrs),
         attrs <- Parse.markdown_within_body(attrs),
         # TODO(akinsey): Implement the following for completion
         # Plugins
         # 1) Track IP (done)

         # Pre Processing

         # 1) clean post title (done)
         # 2) parse/clean post body (wip)
         # 3) handle uploaded images (wip)
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
        ErrorHelpers.render_json_error(conn, 403, "Not logged in, cannot create post")

      {:bypass_lock, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Thread is locked")

      {:is_active, false} ->
        ErrorHelpers.render_json_error(conn, 403, "Account must be active to create posts")

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
  Used to update posts
  """
  def update(conn, attrs) do
    # Authorizations Checks
    with {:auth, %{} = user} <- {:auth, Guardian.Plug.current_resource(conn)},
         :ok <- ACL.allow!(conn, "posts.update"),
         # normally we use model changesets for validating POST requests parameters,
         # this is an exception to save us from doing excessive processing between here
         # and the creation of the post
         post_max_length <-
           Application.get_env(:epochtalk_server, :frontend_config)["post_max_length"],
         id <- Validate.cast(attrs, "id", :integer, required: true),
         thread_id <- Validate.cast(attrs, "thread_id", :integer, required: true),
         _title <-
           Validate.cast(attrs, "title", :string, required: true, max: @max_post_title_length),
         _body <- Validate.cast(attrs, "body", :string, required: true, max: post_max_length),
         user_priority <- ACL.get_user_priority(conn),

         # retreive post data for use with authorizations, preload user's roles
         post <- Post.find_by_id(id, true),

         # Authorizations
         {:bypass_post_owner, true} <-
           {:bypass_post_owner, can_authed_user_bypass_owner_on_post_update(user, post)},
         {:bypass_post_deleted, true} <-
           {:bypass_post_deleted, can_authed_user_bypass_post_deleted_on_post_update(user, post)},
         {:bypass_post_lock, true} <-
           {:bypass_post_lock, can_authed_user_bypass_post_lock_on_post_update(user, post)},
         {:bypass_thread_lock, true} <-
           {:bypass_thread_lock, can_authed_user_bypass_thread_lock_on_post_update(user, post)},
         {:bypass_board_lock, true} <-
           {:bypass_board_lock, can_authed_user_bypass_board_lock_on_post_update(user, post)},
         {:is_active, true} <-
           {:is_active, User.is_active?(user.id)},
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_thread_id(thread_id, user_priority)},
         {:can_write, {:ok, true}} <-
           {:can_write, Board.get_write_access_by_thread_id(thread_id, user_priority)},
         {:board_banned, {:ok, false}} <-
           {:board_banned, BoardBan.banned_from_board?(user, thread_id: thread_id)},

         # Hooks
         attrs <- AutoModeration.moderate(user, attrs),
         attrs <- Mention.username_to_user_id(user, attrs),
         attrs <- Sanitize.html_and_entities_from_title(attrs),
         attrs <- Sanitize.html_and_entities_from_body(attrs),
         attrs <- Parse.markdown_within_body(attrs),
         {:ok, post_data} <- Post.update(attrs, user) do
      # Convert Mention user ids to usernames
      Mention.user_id_to_username(post_data)

      # Correct TSV due to mentions converting username to user id
      Mention.correct_text_search_vector(attrs)

      # render post json data
      render(conn, :update, %{post_data: post_data})

      # TODO(akinsey): the following needs to be completed for this route to be finished

      # Authorizations
      # 1) Check base permissions (Done)
      # 2) Check if user has admin bypass or is post owner, moderator or has priority to edit post (Done)
      # 3) Check if user can bypass deleted post and still edit (Done)
      # 4) Check if user can bypass locked thread and still edit (Done)
      # 5) Check if user can bypass locked board and still edit (Done)
      # 6) Check if user can bypass locked post and still edit (Done)
      # 7) Can read board (Done)
      # 8) Can write board (Done)
      # 9) Check user is board banned (Done)
      # 10) User is active (Done)

      # Pre Processing
      # 1) Clean posts (Done)
      # 2) Parse post (Done)
      # 3) Handle images
      # 4) Handle newbie images

      # Hooks
      # 1) Auto moderation (Done)
      # 2) Mentions (Done)
      #   * username to user id
      #   * user_id to username
      #   * correct text search vector
    else
      {:error, %Ecto.Changeset{} = cs} ->
        ErrorHelpers.render_json_error(conn, 400, cs)

      {:auth, nil} ->
        ErrorHelpers.render_json_error(conn, 403, "Not logged in, cannot create post")

      {:bypass_post_owner, false} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to edit another user's post"
        )

      {:bypass_post_lock, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Post is locked")

      {:bypass_post_deleted, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Post must be unhidden to be edited")

      {:bypass_thread_lock, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Thread is locked")

      {:bypass_board_lock, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Post editing is disabled for this board")

      {:is_active, false} ->
        ErrorHelpers.render_json_error(conn, 403, "Account must be active to create posts")

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
         {:ok, board_banned} <- BoardBan.banned_from_board?(user, thread_id: thread_id),
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
         {:ok, watching_thread} <- WatchThread.user_is_watching(user, thread_id) do
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

  @doc """
  Get `Post` preview by running content through parser
  """
  def preview(conn, attrs) do
    with post_max_length <-
           Map.get(Application.get_env(:epochtalk_server, :frontend_config), :post_max_length),
         body <-
           Validate.cast(attrs, "body", :string, required: true, max: post_max_length, min: 1),
         parsed_body <- Parse.markdown(body) do
      render(conn, :preview, %{parsed_body: parsed_body})
    else
      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot generate preview")
    end
  end

  ## === Private Authorization Helper Functions ===

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
        Thread.self_moderated_by_user?(thread_id, user_id)

      true ->
        false
    end
  end

  defp can_authed_user_bypass_thread_lock_on_post_create(user, thread_id),
    do:
      ACL.bypass_post_owner(
        user,
        %{thread_id: thread_id},
        "posts.create",
        "locked",
        !Thread.locked?(thread_id)
      )

  defp can_authed_user_bypass_owner_on_post_update(user, post),
    do:
      ACL.bypass_post_owner(
        user,
        post,
        "posts.update",
        "owner",
        post.user_id == user.id,
        true,
        true
      )

  defp can_authed_user_bypass_post_lock_on_post_update(user, post),
    do: ACL.bypass_post_owner(user, post, "posts.update", "locked", !post.locked, true)

  defp can_authed_user_bypass_post_deleted_on_post_update(user, post),
    do: ACL.bypass_post_owner(user, post, "posts.update", "deleted", !post.deleted, true)

  defp can_authed_user_bypass_thread_lock_on_post_update(user, post),
    do:
      ACL.bypass_post_owner(
        user,
        post,
        "posts.update",
        "locked",
        !Thread.locked?(post.thread_id),
        true
      )

  defp can_authed_user_bypass_board_lock_on_post_update(user, post),
    do:
      ACL.bypass_post_owner(
        user,
        post,
        "posts.update",
        "locked",
        !Board.is_post_edit_disabled_by_thread_id(post.thread_id, post.created_at),
        true
      )
end
