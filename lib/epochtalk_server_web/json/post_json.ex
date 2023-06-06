defmodule EpochtalkServerWeb.PostJSON do

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
    %{
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
    }
  end
end
