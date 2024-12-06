defmodule EpochtalkServerWeb.Controllers.Poll do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Poll` related API requests
  """
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.Helpers.Validate
  alias EpochtalkServerWeb.Helpers.ACL
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.BoardBan
  alias EpochtalkServer.Models.Poll
  alias EpochtalkServer.Models.PollResponse

  @doc """
  Used to create `Poll` in existing `Thread`
  """
  def create(conn, attrs) do
    with user <- Guardian.Plug.current_resource(conn),
         thread_id <- Validate.cast(attrs, "thread_id", :integer, required: true),
         :ok <- ACL.allow!(conn, "threads.createPoll"),
         user_priority <- ACL.get_user_priority(conn),
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_thread_id(thread_id, user_priority)},
         {:can_write, {:ok, true}} <-
           {:can_write, Board.get_write_access_by_thread_id(thread_id, user_priority)},
         {:is_active, true} <-
           {:is_active, User.is_active?(user.id)},
         {:board_banned, {:ok, false}} <-
           {:board_banned, BoardBan.banned_from_board?(user, thread_id: thread_id)},
         {:poll_exists, false} <- {:poll_exists, Poll.exists(thread_id)},
         {:bypass_post_owner, true} <-
           {:bypass_post_owner, can_authed_user_bypass_owner_on_poll_create(user, thread_id)},
         {:ok, _} <- Poll.create(attrs),
         poll <- Poll.by_thread(thread_id) do
      render(conn, :poll, %{poll: poll, has_voted: false})
    else
      {:can_read, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to read"
        )

      {:can_write, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to write"
        )

      {:bypass_post_owner, false} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to create a poll for another user's thread"
        )

      {:board_banned, {:ok, true}} ->
        ErrorHelpers.render_json_error(conn, 403, "Unauthorized, you are banned from this board")

      {:poll_exists, true} ->
        ErrorHelpers.render_json_error(conn, 400, "Error, poll already exists")

      {:is_active, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Account must be active to create poll")

      {:error, data} ->
        ErrorHelpers.render_json_error(conn, 400, data)

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot create poll")
    end
  end

  @doc """
  Used to update `Poll`
  """
  def update(conn, attrs) do
    with user <- Guardian.Plug.current_resource(conn),
         thread_id <- Validate.cast(attrs, "thread_id", :integer, required: true),
         :ok <- ACL.allow!(conn, "threads.editPoll"),
         user_priority <- ACL.get_user_priority(conn),
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_thread_id(thread_id, user_priority)},
         {:can_write, {:ok, true}} <-
           {:can_write, Board.get_write_access_by_thread_id(thread_id, user_priority)},
         {:is_active, true} <-
           {:is_active, User.is_active?(user.id)},
         {:board_banned, {:ok, false}} <-
           {:board_banned, BoardBan.banned_from_board?(user, thread_id: thread_id)},
         {:poll_exists, true} <- {:poll_exists, Poll.exists(thread_id)},
         {:bypass_post_owner, true} <-
           {:bypass_post_owner, can_authed_user_bypass_owner_on_poll_update(user, thread_id)},
         {:ok, poll} <- Poll.update(attrs) do
      render(conn, :update, poll: poll)
    else
      {:can_read, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to read"
        )

      {:can_write, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to write"
        )

      {:bypass_post_owner, false} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to edit another user's poll"
        )

      {:board_banned, {:ok, true}} ->
        ErrorHelpers.render_json_error(conn, 403, "Unauthorized, you are banned from this board")

      {:poll_exists, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Error, poll does not exist")

      {:is_active, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Account must be active to edit poll")

      {:error, data} ->
        ErrorHelpers.render_json_error(conn, 400, data)

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot edit poll")
    end
  end

  @doc """
  Used to lock `Poll`
  """
  def lock(conn, attrs) do
    with user <- Guardian.Plug.current_resource(conn),
         thread_id <- Validate.cast(attrs, "thread_id", :integer, required: true),
         locked <- Validate.cast(attrs, "locked", :boolean, required: true),
         :ok <- ACL.allow!(conn, "threads.lockPoll"),
         user_priority <- ACL.get_user_priority(conn),
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_thread_id(thread_id, user_priority)},
         {:can_write, {:ok, true}} <-
           {:can_write, Board.get_write_access_by_thread_id(thread_id, user_priority)},
         {:is_active, true} <-
           {:is_active, User.is_active?(user.id)},
         {:board_banned, {:ok, false}} <-
           {:board_banned, BoardBan.banned_from_board?(user, thread_id: thread_id)},
         {:poll_exists, true} <- {:poll_exists, Poll.exists(thread_id)},
         {:bypass_post_owner, true} <-
           {:bypass_post_owner, can_authed_user_bypass_owner_on_poll_lock(user, thread_id)},
         {1, nil} <- Poll.set_locked(thread_id, locked) do
      render(conn, :lock, poll: %{thread_id: thread_id, locked: locked})
    else
      {:can_read, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to read"
        )

      {:can_write, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to write"
        )

      {:bypass_post_owner, false} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to modify the lock on another user's poll"
        )

      {:board_banned, {:ok, true}} ->
        ErrorHelpers.render_json_error(conn, 403, "Unauthorized, you are banned from this board")

      {:poll_exists, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Error, poll does not exist")

      {:is_active, false} ->
        ErrorHelpers.render_json_error(
          conn,
          400,
          "Account must be active to modify lock on poll"
        )

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot lock poll")
    end
  end

  @doc """
  Used to vote on `Poll`
  """
  def vote(conn, attrs) do
    with user <- Guardian.Plug.current_resource(conn),
         thread_id <- Validate.cast(attrs, "thread_id", :integer, required: true),
         answer_ids <- attrs["answer_ids"],
         {:valid_answers_list, true} <- {:valid_answers_list, is_list(answer_ids)},

         # Authorizations
         :ok <- ACL.allow!(conn, "threads.vote"),
         user_priority <- ACL.get_user_priority(conn),
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_thread_id(thread_id, user_priority)},
         {:can_write, {:ok, true}} <-
           {:can_write, Board.get_write_access_by_thread_id(thread_id, user_priority)},
         {:is_active, true} <-
           {:is_active, User.is_active?(user.id)},
         {:board_banned, {:ok, false}} <-
           {:board_banned, BoardBan.banned_from_board?(user, thread_id: thread_id)},
         {:poll_exists, true} <- {:poll_exists, Poll.exists(thread_id)},
         {:poll_running, true} <- {:poll_running, Poll.running(thread_id)},
         {:poll_unlocked, true} <- {:poll_unlocked, Poll.unlocked(thread_id)},
         {:poll_not_voted, true} <-
           {:poll_not_voted, Poll.has_not_voted(thread_id, user.id)},
         {:poll_valid_answers, true} <-
           {:poll_valid_answers, length(answer_ids) <= Poll.max_answers(thread_id)},

         # create poll response and query return data
         {:ok, _} <- PollResponse.create(attrs, user.id),
         poll <- Poll.by_thread(thread_id) do
      render(conn, :poll, %{poll: poll, has_voted: true})
    else
      {:valid_answers_list, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Error, 'answer_ids' must be a list")

      {:can_read, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to read"
        )

      {:can_write, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to write"
        )

      {:poll_exists, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Error, poll does not exist")

      {:poll_running, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Error, poll is not currently running")

      {:poll_unlocked, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Error, poll is locked")

      {:poll_not_voted, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Error, you have already voted on this poll")

      {:poll_valid_answers, false} ->
        ErrorHelpers.render_json_error(
          conn,
          400,
          "Error, 'answer_ids' length too long, too many answers"
        )

      {:is_active, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Account must be active to vote")

      {:board_banned, {:ok, true}} ->
        ErrorHelpers.render_json_error(conn, 403, "Unauthorized, you are banned from this board")

      {:error, :board_does_not_exist} ->
        ErrorHelpers.render_json_error(conn, 400, "Error, board does not exist")

      {:error, data} ->
        ErrorHelpers.render_json_error(conn, 400, data)

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot cast vote")
    end
  end

  @doc """
  Used to delete vote on `Poll`
  """
  def delete_vote(conn, attrs) do
    with user <- Guardian.Plug.current_resource(conn),
         thread_id <- Validate.cast(attrs, "thread_id", :integer, required: true),

         # Authorizations
         :ok <- ACL.allow!(conn, "threads.removeVote"),
         user_priority <- ACL.get_user_priority(conn),
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_thread_id(thread_id, user_priority)},
         {:can_write, {:ok, true}} <-
           {:can_write, Board.get_write_access_by_thread_id(thread_id, user_priority)},
         {:is_active, true} <-
           {:is_active, User.is_active?(user.id)},
         {:board_banned, {:ok, false}} <-
           {:board_banned, BoardBan.banned_from_board?(user, thread_id: thread_id)},
         {:poll_exists, true} <- {:poll_exists, Poll.exists(thread_id)},
         {:poll_running, true} <- {:poll_running, Poll.running(thread_id)},
         {:poll_unlocked, true} <- {:poll_unlocked, Poll.unlocked(thread_id)},
         {:poll_change_vote, true} <-
           {:poll_change_vote, Poll.allow_change_vote(thread_id)},

         # delete poll response and query return data
         {_count, _deleted} <- PollResponse.delete(thread_id, user.id),
         poll <- Poll.by_thread(thread_id) do
      render(conn, :poll, %{poll: poll, has_voted: false})
    else
      {:can_read, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to read"
        )

      {:can_write, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "Unauthorized, you do not have permission to write"
        )

      {:poll_exists, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Error, poll does not exist")

      {:poll_running, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Error, poll is not currently running")

      {:poll_unlocked, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Error, poll is locked")

      {:poll_change_vote, false} ->
        ErrorHelpers.render_json_error(
          conn,
          400,
          "Error, you can't change your vote on this poll"
        )

      {:is_active, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Account must be active to vote")

      {:board_banned, {:ok, true}} ->
        ErrorHelpers.render_json_error(conn, 403, "Unauthorized, you are banned from this board")

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot cast vote")
    end
  end

  # === Private Authorization Helpers Functions ===

  defp can_authed_user_bypass_owner_on_poll_create(user, thread_id) do
    post = Thread.get_first_post_data_by_id(thread_id)

    ACL.bypass_post_owner(
      user,
      post,
      "threads.createPoll",
      "owner",
      post.user_id == user.id,
      true,
      true
    )
  end

  defp can_authed_user_bypass_owner_on_poll_update(user, thread_id) do
    post = Thread.get_first_post_data_by_id(thread_id)

    ACL.bypass_post_owner(
      user,
      post,
      "threads.editPoll",
      "owner",
      post.user_id == user.id,
      true,
      true
    )
  end

  defp can_authed_user_bypass_owner_on_poll_lock(user, thread_id) do
    post = Thread.get_first_post_data_by_id(thread_id)

    ACL.bypass_post_owner(
      user,
      post,
      "threads.editPoll",
      "owner",
      post.user_id == user.id,
      true,
      true
    )
  end
end
