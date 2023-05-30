defmodule EpochtalkServerWeb.PostController do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Post` related API requests
  """
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.Helpers.Validate
  alias EpochtalkServerWeb.Helpers.ACL
  alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Models.Thread
  # alias EpochtalkServer.Models.Board
  # alias EpochtalkServer.Models.BoardBan
  # alias EpochtalkServer.Models.BoardMapping
  # alias EpochtalkServer.Models.BoardModerator


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
  Used to retrieve posts by thread
  """
  def by_thread(conn, attrs) do
    with thread_id <- Validate.cast(attrs, "thread_id", :integer, required: true),
         page <- Validate.cast(attrs, "page", :integer, default: 1),
         start <- Validate.cast(attrs, "start", :string),
         limit <- Validate.cast(attrs, "limit", :integer, default: 25),
         user <- Guardian.Plug.current_resource(conn),
         user_priority <- ACL.get_user_priority(conn) do
      # render(conn, :by_thread, %{
      #   posts: posts,
      #   write_access: write_access && is_map(user) && !board_banned,
      #   board_banned: board_banned,
      #   user: user,
      #   user_priority: user_priority,
      #   board_id: board_id,
      #   board_mapping: board_mapping,
      #   board_moderators: board_moderators,
      #   page: page,
      #   field: field,
      #   limit: limit,
      #   desc: desc
      # })
    else
      # {:error, :board_does_not_exist} ->
      #   ErrorHelpers.render_json_error(conn, 400, "Error, thread does not exist")

      # {:can_read, {:ok, false}} ->
      #   ErrorHelpers.render_json_error(conn, 403, "Unauthorized, you do not have permission")

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot get posts by thread")
    end
  end
end
