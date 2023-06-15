defmodule EpochtalkServerWeb.PostJSON do
  alias EpochtalkServerWeb.BoardJSON
  alias EpochtalkServerWeb.ThreadJSON

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

    %{
      board: formatted_board,
      posts: posts,
      thread: formatted_thread,
      write_access: write_access,
      board_banned: board_banned,
      user: user,
      metadata: %{
        metric_rank_maps: metric_rank_maps,
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
end
