defmodule EpochtalkServerWeb.PostJSON do
  alias EpochtalkServerWeb.BoardJSON

  @moduledoc """
  Renders and formats `Post` data, in JSON format for frontend
  """

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
        desc: desc
      }) do
    # format board data
    board =
      BoardJSON.format_board_data_for_find(
        board_moderators,
        board_mapping,
        thread.board_id,
        user_priority
      )

    poll = format_poll_data_for_by_thread(poll)

    %{
      board: board,
      posts: posts,
      thread: Map.put(thread, :poll, poll),
      write_access: write_access,
      board_banned: board_banned,
      user: user,
      page: page,
      start: start,
      limit: limit,
      desc: desc
    }
  end

  # TODO(akinsey): format poll reponses and answers to match route output
  defp format_poll_data_for_by_thread(poll) do
    poll
  end
end
