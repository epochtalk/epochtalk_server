defmodule EpochtalkServerWeb.Controllers.ThreadJSON do
  alias EpochtalkServerWeb.Controllers.BoardJSON

  @moduledoc """
  Renders and formats `Thread` data, in JSON format for frontend
  """

  @doc """
  Renders recent `Thread` data.
  """
  def recent(%{
        threads: threads
      }) do
    threads
    |> Enum.map(fn thread ->
      %{id: thread.id, slug: thread.slug, updated_at: thread.updated_at}
    end)
  end

  @doc """
  Renders `Thread` for create.
  """
  def create(%{
        thread_data: thread_data
      }) do
    post = thread_data.post
    thread = thread_data.post.thread

    %{
      body: post.content["body"],
      created_at: thread.created_at,
      deleted: post.deleted,
      id: post.id,
      locked: thread.locked,
      position: post.position,
      slug: thread.slug,
      thread_id: thread.id,
      title: post.content["title"],
      user_id: post.user_id
    }
  end

  @doc """
  Renders `Thread` for by_board query.
  """
  def by_board(%{
        threads: threads,
        board_moderators: board_moderators,
        board_mapping: board_mapping,
        board_id: board_id,
        user: user,
        user_priority: user_priority,
        write_access: write_access,
        board_banned: board_banned,
        watched: watched,
        page: page,
        field: field,
        limit: limit,
        desc: desc
      }) do
    # format board data
    board =
      BoardJSON.format_board_data_for_find(
        board_moderators,
        board_mapping,
        board_id,
        user_priority
      )
      |> Map.put(:watched, watched)

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
      desc: desc
    }

    # return results and append board_banned only if user is banned
    if board_banned, do: Map.put(result, :board_banned, board_banned), else: result
  end

  @doc """
  Renders `Thread` id for slug to id route.
  """
  def slug_to_id(%{id: id}), do: %{id: id}

  ## === Public Fomatting Functions ===

  @doc """
  Used to format `Thread` user data from db into the format the frontend expects
  """
  def format_user_data(thread) do
    # handle deleted user
    thread =
      if thread.user_deleted,
        do: thread |> Map.put(:user_id, '') |> Map.put(:username, ''),
        else: thread

    # format user output
    thread =
      thread
      |> Map.put(:user, %{
        id: thread.user_id,
        username: thread.username,
        deleted: thread.user_deleted
      })

    # clean up user data
    thread
    |> Map.delete(:user_id)
    |> Map.delete(:username)
    |> Map.delete(:user_deleted)
  end

  ## === Private Helper Functions ===

  defp format_thread_data(thread, user_id) do
    thread
    |> format_user_data()
    |> format_last_post_data(user_id)
    |> format_last_post_user_data()
  end

  defp format_last_post_data(thread, user_id) do
    thread =
      cond do
        is_integer(user_id) and !thread.last_viewed ->
          thread
          |> Map.put(:has_new_post, true)
          |> Map.put(:last_unread_position, 1)

        is_integer(user_id) and user_id != thread.last_post_user_id and
            NaiveDateTime.compare(thread.last_viewed, thread.last_post_created_at) == :lt ->
          thread
          |> Map.put(:has_new_post, true)
          |> Map.put(:last_unread_position, thread.post_position)
          |> Map.put(:last_unread_post_id, thread.post_id)

        true ->
          thread
      end

    # clean up last post data
    thread
    |> Map.delete(:post_id)
    |> Map.delete(:post_position)
    |> Map.delete(:last_viewed)
  end

  defp format_last_post_user_data(thread) do
    thread =
      if thread.last_post_deleted || thread.last_post_user_deleted do
        thread
        |> Map.put(:last_deleted, true)
        |> Map.delete(:last_post_username)
      else
        thread
      end

    # clean up last post user data
    thread
    |> Map.delete(:last_post_deleted)
    |> Map.delete(:last_post_user_deleted)
    |> Map.delete(:last_post_user_id)
  end
end
