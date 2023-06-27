defmodule EpochtalkServerWeb.Controllers.PostJSON do
  alias EpochtalkServerWeb.Controllers.BoardJSON
  alias EpochtalkServerWeb.Controllers.ThreadJSON

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
        trust_boards: trust_boards,
        watched: watched
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
      |> Map.put(
        :trust_visible,
        Enum.filter(trust_boards, &(&1.board_id == thread.board_id)) != []
      )
      |> Map.put(:watched, watched)

    formatted_posts = posts |> Enum.map(&format_post_data_for_by_thread(&1))

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
      role_name: post.role_name
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
