defmodule EpochtalkServerWeb.Controllers.Post do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Post` related API requests
  """
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.Helpers.Validate
  alias EpochtalkServerWeb.Helpers.ACL
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
  alias EpochtalkServer.Models.WatchThread

  # @doc """
  # Used to create posts
  # """
  # def create(conn, attrs) do
  #   with user <- Guardian.Plug.current_resource(conn),
  #        {:ok, post_data} <- Post.create(attrs, user.id) do
  #     render(conn, :create, %{post_data: post_data})
  #   else
  #     {:error, %Ecto.Changeset{} = cs} ->
  #       ErrorHelpers.render_json_error(conn, 400, cs)

  #     _ ->
  #       ErrorHelpers.render_json_error(conn, 400, "Error, cannot create post")
  #   end
  # end

  @doc """
  Used to retrieve `Posts` by `Thread`

  Test Cases:
  1) Authenticated vs Not Authenticated
  2) Thread with Poll vs no Poll
  3) Query with start position vs page
  4) Read/Write access test against user priority (postable/writable by on board)
  5) Base permission check
  6) Authorizations tests (TODO: implement authorizations first)
  7) Board ban on authed user
  8) Board and Thread metadata is correct (ex: board.signature_disabled, thread.trust_visible)
  """
  def by_thread(conn, attrs) do
    with thread_id <- Validate.cast(attrs, "thread_id", :integer, required: true),
         page <- Validate.cast(attrs, "page", :integer, default: 1),
         start <- Validate.cast(attrs, "start", :string),
         limit <- Validate.cast(attrs, "limit", :integer, default: 25),
         desc <- Validate.cast(attrs, "desc", :boolean, default: true),
         user <- Guardian.Plug.current_resource(conn),
         user_priority <- ACL.get_user_priority(conn),
         :ok <- ACL.allow!(conn, "posts.byThread"),
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_thread_id(thread_id, user_priority)},
         view_deleted_posts <- can_authed_user_view_deleted_posts(user, thread_id),
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
         posts <- Trust.maybe_append_trust_stats_to_posts(posts, user),
         thread <- Trust.maybe_append_trust_visible_to_thread(thread, user),
         posts <- UserActivity.append_user_activity_to_posts(posts),
         metric_rank_maps <- MetricRankMap.all_merged(),
         ranks <- Rank.all(),
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
end
