defmodule EpochtalkServerWeb.ThreadView do
  use EpochtalkServerWeb, :view

  alias EpochtalkServerWeb.BoardView
  @moduledoc """
  Renders and formats `Thread` data, in JSON format for frontend
  """

  @doc """
  Renders whatever data it is passed when template not found. Data pass through
  for rendering misc responses (ex: {found: true} or {success: true})
  ## Example
      iex> EpochtalkServerWeb.ThreadView.render("DoesNotExist.json", data: %{anything: "abc"})
      %{anything: "abc"}
      iex> EpochtalkServerWeb.ThreadView.render("DoesNotExist.json", data: %{success: true})
      %{success: true}
  """
  def template_not_found(_template, %{data: data}), do: data

  @doc """
  Renders recent `Thread` data.
  """
  def render("recent.json", %{
        threads: threads
      }) do
    threads
    |> Enum.map(fn thread ->
      %{id: thread.id, slug: thread.slug, updated_at: thread.updated_at}
    end)
  end

  @doc """
  Renders `Board` for find query.
  """
  def render("by_board.json", %{
        threads: threads,
        board_moderators: board_moderators,
        board_mapping: board_mapping,
        board_id: board_id,
        user: user,
        user_priority: user_priority,
        write_access: write_access,
        board_banned: board_banned,
        page: page,
        field: field,
        limit: limit,
        desc: desc
      }) do
    # format board data
    board = BoardView.format_board_data_for_find(board_moderators, board_mapping, board_id, user_priority)

    # format thread data
    user_id = if is_nil(user), do: nil, else: user.id
    normal = threads.normal |> Enum.map(&format_thread_data(&1, user_id))
    sticky = threads.sticky |> Enum.map(&format_thread_data(&1, user_id))

    # build by_board results
    result = %{
      normal: normal,
      sticky: sticky,
      board: board,
      write_access: write_access,
      page: page,
      field: field,
      limit: limit,
      desc: desc,
    }

    # return results and append board_banned only if user is banned
    if board_banned, do: Map.put(result, :board_banned, board_banned), else: result
  end

  defp format_thread_data(thread, user_id) do
    # handle deleted user
    thread = if thread.user_deleted,
      do: thread |> Map.put(:user_id, '') |> Map.put(:username, ''),
      else: thread

    # format user output
    thread = thread |> Map.put(:user, %{
      id: thread.user_id,
      username: thread.username,
      deleted: thread.user_deleted
    })

    # clean up user data
    thread = thread
      |> Map.delete(:user_id)
      |> Map.delete(:username)
      |> Map.delete(:user_deleted)

    # format last post data
    thread = cond do
      is_integer(user_id) and !thread.last_viewed ->
        thread
          |> Map.put(:has_new_post, true)
          |> Map.put(:last_unread_position, 1)
      is_integer(user_id) and user_id != thread.last_post_user_id and thread.last_viewed <= thread.last_post_created_at ->
        thread
          |> Map.put(:has_new_post, true)
          |> Map.put(:last_unread_position, thread.post_position)
          |> Map.put(:last_unread_post_id, thread.post_id)
      true -> thread
    end

    # clean up last post data
    thread = thread
      |> Map.delete(:post_id)
      |> Map.delete(:post_position)
      |> Map.delete(:last_viewed)

    # format last post user data
    thread = if thread.last_post_deleted or thread.last_post_user_deleted do
      thread
        |> Map.put(:last_deleted, true)
        |> Map.delete(:last_post_username)
    else
      thread
    end

    # clean up last post user data
    thread = thread
      |> Map.delete(:last_post_deleted)
      |> Map.delete(:last_post_user_deleted)
      |> Map.delete(:last_post_user_id)

    # return formatted thread
    thread
  end
end
