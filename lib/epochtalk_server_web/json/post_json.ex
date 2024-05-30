defmodule EpochtalkServerWeb.Controllers.PostJSON do
  alias EpochtalkServerWeb.Controllers.BoardJSON
  alias EpochtalkServerWeb.Controllers.ThreadJSON
  alias EpochtalkServerWeb.Helpers.ACL
  alias EpochtalkServerWeb.Helpers.ProxyConversion

  @moduledoc """
  Renders and formats `Post` data, in JSON format for frontend
  """

  @doc """
  Renders `Post` data after creating new `Post`
  """
  def create(%{
        post_data: post_data
      }) do
    post_data
  end

  @doc """
  Renders `Post` data after updating existing `Post`
  """
  def update(%{
        post_data: post_data
      }) do
    post_data
  end

  @doc """
  Renders `Post` data for preview purposes

    ## Example
    iex> parsed_body = %{parsed_body: "<p><strong>Hello World</strong><p>"}
    iex> EpochtalkServerWeb.Controllers.PostJSON.preview(parsed_body)
    parsed_body
  """
  def preview(%{
        parsed_body: parsed_body
      }) do
    %{parsed_body: parsed_body}
  end

  @doc """
  Renders all `Post` for a particular `Thread`.
  """
  def by_thread(%{
        posts: posts,
        poll: poll,
        thread: thread,
        write_access: write_access,
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
        watched: watched,
        view_deleted_posts: view_deleted_posts
      }) do
    formatted_board =
      BoardJSON.format_board_data_for_find(
        board_moderators,
        board_mapping,
        thread.board_id,
        user_priority
      )

    formatted_poll = format_poll_data_for_by_thread(poll, user)

    formatted_thread =
      thread
      |> ThreadJSON.format_user_data()
      |> Map.put(:poll, formatted_poll)
      |> Map.put(:watched, watched)

    formatted_posts =
      posts
      |> Enum.map(&format_post_data_for_by_thread(&1))
      |> handle_deleted_posts(formatted_thread, user, user_priority, view_deleted_posts)

    %{
      board: formatted_board,
      posts: formatted_posts,
      thread: formatted_thread,
      write_access: write_access,
      board_banned: board_banned,
      metadata: %{
        rank_metric_maps: metric_rank_maps,
        ranks: ranks
      },
      page: page,
      start: start,
      limit: limit,
      desc: desc
    }
  end

  def by_thread_proxy(%{
        posts: posts,
        page: page,
        limit: limit
      }) do
    {:ok, thread} =
      if is_map(posts) do
        ProxyConversion.build_model("thread", [posts.thread_id], page, limit)
      else
        ProxyConversion.build_model("thread", [List.first(posts).thread_id], page, limit)
      end

    # format board data
    {:ok, board} = ProxyConversion.build_model("board", [thread.board_id], 1, 1)

    board =
      board
      |> Map.put(:moderators, [])

    # format post data
    posts =
      posts
      |> Enum.map(&format_proxy_post_data_for_by_thread(&1))

    # build by_thread results
    %{
      posts: posts,
      thread: thread,
      board: board,
      page: page,
      limit: limit
    }
  end

  ## === Private Helper Functions ===

  defp handle_deleted_posts(posts, thread, user, authed_user_priority, view_deleted_posts) do
    authed_user_id = if is_nil(user), do: nil, else: user.id

    has_self_mod_bypass =
      ACL.has_permission(user, "posts.byThread.bypass.viewDeletedPosts.selfMod")

    has_priority_bypass =
      ACL.has_permission(user, "posts.byThread.bypass.viewDeletedPosts.priority")

    has_self_mod_permissions = has_self_mod_bypass or has_priority_bypass

    authed_user_is_self_mod =
      if thread != nil,
        do: thread.user.id == authed_user_id and thread.moderated and has_self_mod_permissions,
        else: false

    viewable_in_board_with_id = if is_list(view_deleted_posts), do: view_deleted_posts

    cleaned_posts =
      posts
      |> Enum.map(
        &handle_deleted_post(
          &1,
          authed_user_id,
          authed_user_priority,
          authed_user_is_self_mod,
          view_deleted_posts,
          viewable_in_board_with_id
        )
      )

    # return posts for now
    cleaned_posts
  end

  defp handle_deleted_post(
         post,
         authed_user_id,
         authed_user_priority,
         authed_user_is_self_mod,
         view_deleted_posts,
         viewable_in_board_with_id
       ) do
    # check if metadata map exists
    metadata_map_exists = !!post.metadata and Map.keys(post.metadata) != []

    # get information about how current post was hidden
    post_hidden_by_priority =
      if metadata_map_exists && post.metadata["hidden_by_priority"] != nil,
        do: post.metadata["hidden_by_priority"],
        else: post.user.priority

    post_hidden_by_id =
      if metadata_map_exists && post.metadata["hidden_by_id"] != nil,
        do: post.metadata["hidden_by_id"],
        else: post.user.id

    # check if user has priority to view hidden post,
    # or if the user was the one who hid the post
    authed_user_has_priority = authed_user_priority <= post_hidden_by_priority
    authed_user_hid_post = post_hidden_by_id == authed_user_id

    post_is_viewable =
      post_viewable?(
        post,
        authed_user_id,
        authed_user_is_self_mod,
        authed_user_has_priority,
        authed_user_hid_post,
        view_deleted_posts,
        viewable_in_board_with_id
      )

    # delete posts that are marked deleted, the user was deleted, or the board is not visible
    post_is_deleted = post.deleted || post.user.deleted || Map.get(post, :board_visible) == false

    # only hide deleted posts if user does not has permissions to see them
    post = maybe_delete_post_data(post, post_is_viewable, post_is_deleted)

    # return updated post
    post
  end

  defp post_viewable?(
         post,
         authed_user_id,
         authed_user_is_self_mod,
         authed_user_has_priority,
         authed_user_hid_post,
         view_deleted_posts,
         viewable_in_board_with_id
       ) do
    cond do
      # user owns the post
      authed_user_id == post.user.id ->
        true

      # user is viewing post within a board they moderate
      !!viewable_in_board_with_id and post.board_id in viewable_in_board_with_id ->
        true

      # if view_deleted_posts is true, every post is viewable
      view_deleted_posts ->
        true

      # if the authed user is a self mod of the current thread, and
      # the post is not deleted, then the post is viewable if they have
      # the appropriate priority or they are the one who hid the post
      authed_user_is_self_mod and !!post.deleted ->
        authed_user_has_priority or authed_user_hid_post

      # default to false
      true ->
        false
    end
  end

  defp maybe_delete_post_data(post, post_is_viewable, post_is_deleted) do
    post =
      cond do
        # post is deleted but user has permission to view it, hide the post
        post_is_viewable and post_is_deleted ->
          Map.put(post, :hidden, true)

        # post is deleted and user does not have permission to view it, modify and delete post
        post_is_deleted ->
          %{
            id: post.id,
            hidden: true,
            _deleted: true,
            position: post.position,
            thread_title: "deleted",
            user: %{}
          }

        # post was not marked deleted, return the original post
        true ->
          post
      end

    # remove deleted property if not set to true
    post = if Map.get(post, :deleted) != true, do: Map.delete(post, :deleted), else: post

    # remove board_visible property
    post = Map.delete(post, :board_visible)

    # remove user deleted property from nested user map
    Map.put(post, :user, Map.delete(post.user, :deleted))
  end

  defp format_poll_data_for_by_thread(nil, _), do: nil

  defp format_poll_data_for_by_thread(poll, user) do
    formatted_poll = %{
      id: poll.id,
      change_vote: poll.change_vote,
      display_mode: poll.display_mode,
      expiration: poll.expiration,
      locked: poll.locked,
      max_answers: poll.max_answers,
      question: poll.question
    }

    answers =
      Enum.map(poll.poll_answers, fn answer ->
        selected =
          if is_nil(user),
            do: false,
            else: answer.poll_responses |> Enum.filter(&(&1.user_id == user.id)) |> length() > 0

        %{
          answer: answer.answer,
          id: answer.id,
          selected: selected,
          votes: answer.poll_responses |> length()
        }
      end)

    has_voted = answers |> Enum.filter(& &1.selected) |> length() > 0

    formatted_poll
    |> Map.put(:answers, answers)
    |> Map.put(:has_voted, has_voted)
  end

  defp format_post_data_for_by_thread(post) do
    post
    # if body_html does not exist, default to post.body
    |> Map.put(:body_html, post.body_html || post.body)
    |> Map.put(:user, %{
      id: post.user_id,
      name: post.name,
      original_poster: post.original_poster,
      username: post.username,
      priority: if(is_nil(post.priority), do: post.default_priority, else: post.priority),
      deleted: post.user_deleted,
      signature: post.signature,
      post_count: post.post_count,
      highlight_color: post.highlight_color,
      role_name: post.role_name,
      stats: Map.get(post, :user_trust_stats),
      ignored: Map.get(post, :user_ignored),
      _ignored: Map.get(post, :user_ignored),
      activity: Map.get(post, :user_activity)
    })
    |> Map.delete(:user_id)
    |> Map.delete(:username)
    |> Map.delete(:priority)
    |> Map.delete(:default_priority)
    |> Map.delete(:original_poster)
    |> Map.delete(:name)
    |> Map.delete(:user_deleted)
    |> Map.delete(:post_count)
    |> Map.delete(:signature)
    |> Map.delete(:highlight_color)
    |> Map.delete(:role_name)
  end

  defp format_proxy_post_data_for_by_thread(post) do
    post
    # if body_html does not exist, default to post.body
    |> Map.put(:body_html, post.body)
    |> Map.put(:user, %{
      id: post.user_id,
      username: post.poster_name
      # original_poster: post.original_poster,
      # username: post.username,
      # priority: if(is_nil(post.priority), do: post.default_priority, else: post.priority)
      # deleted: post.user_deleted,
      # signature: post.signature,
      # post_count: post.post_count,
      # highlight_color: post.highlight_color,
      # role_name: post.role_name,
      # stats: Map.get(post, :user_trust_stats),
      # ignored: Map.get(post, :user_ignored),
      # _ignored: Map.get(post, :user_ignored),
      # activity: Map.get(post, :user_activity)
    })
    |> Map.delete(:user_id)
    |> Map.delete(:poster_name)
  end
end
