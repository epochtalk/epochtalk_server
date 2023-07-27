defmodule EpochtalkServerWeb.Controllers.PostJSON do
  alias EpochtalkServerWeb.Controllers.BoardJSON
  alias EpochtalkServerWeb.Controllers.ThreadJSON
  alias EpochtalkServerWeb.Helpers.ACL

  @moduledoc """
  Renders and formats `Post` data, in JSON format for frontend
  """

  @doc """
  Renders all `Post` for a particular `Thread`.

  TODO(akinsey): implement trust and watched hook information for thread
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

    formatted_posts = posts
      |> Enum.map(&format_post_data_for_by_thread(&1))
      |> clean_posts(formatted_thread, user, user_priority, view_deleted_posts)

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

  ## === Private Helper Functions ===

  defp clean_posts(posts, thread, user, authed_user_priority, view_deleted_posts, override_allow_view \\ false) do
    authed_user_id = if user, do: user.id, else: nil
    has_self_mod_bypass = ACL.has_permission(user, "posts.byThread.bypass.viewDeletedPosts.selfMod")
    has_priority_bypass = ACL.has_permission(user, "posts.byThread.bypass.viewDeletedPosts.priority")
    is_self_mod = if thread, do: thread.user.id == authed_user_id and thread.moderated, else: false

    view_deleted_posts_is_board_list = is_list(view_deleted_posts)

    Enum.map(posts, fn post ->
      # check if metadata map exists
      metadata_map_exists = !!post.metadata and Map.keys(post.metadata) != []

      # get information about how current post was hidden
      post_hidden_by_priority = if metadata_map_exists,
        do: post.metadata.hidden_by_priority,
        else: post.user.priority
      post_hidden_by_id = if metadata_map_exists,
        do: post.metadata.hidden_by_id,
        else: post.user.id

      # check if user has priority to view hidden post,
      # or if the user was the one who hid the post
      authed_user_has_priority = authed_user_priority <= post_hidden_by_priority
      authed_user_hid_post = post_hidden_by_id == authed_user_id
    end)

    # return posts for now
    posts
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
    # TODO(akinsey): this is a temp hack to get posts to display
    |> Map.put(:body_html, post.body)
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
      stats: Map.get(post, :user_trust_stats)
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
end
