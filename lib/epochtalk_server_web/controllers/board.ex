defmodule EpochtalkServerWeb.Controllers.Board do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Board` related API requests
  """
  alias EpochtalkServer.Models.BoardModerator
  alias EpochtalkServer.Models.BoardMapping
  alias EpochtalkServer.Models.Category
  alias EpochtalkServer.Models.Board
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.Helpers.Validate
  alias EpochtalkServerWeb.Helpers.ACL
  alias EpochtalkServerWeb.Helpers.ProxyConversion

  plug :check_proxy when action in [:slug_to_id, :by_category]

  @doc """
  Used to retrieve categorized boards
  """
  def by_category(conn, attrs) do
    with :ok <- ACL.allow!(conn, "boards.allCategories"),
         stripped <- Validate.cast(attrs, "stripped", :boolean, default: false),
         user_priority <- ACL.get_user_priority(conn),
         board_mapping <- BoardMapping.all(stripped: stripped),
         board_moderators <- BoardModerator.all(),
         categories <- Category.all() do
      render(conn, :by_category, %{
        categories: categories,
        board_moderators: board_moderators,
        board_mapping: board_mapping,
        user_priority: user_priority
      })
    else
      _ -> ErrorHelpers.render_json_error(conn, 400, "Error, cannot fetch boards")
    end
  end

  @doc """
  Used to find a specific board
  """
  def find(conn, attrs) do
    with :ok <- ACL.allow!(conn, "boards.find"),
         id <- Validate.cast(attrs, "id", :integer, required: true),
         user_priority <- ACL.get_user_priority(conn),
         {:can_read, {:ok, true}} <-
           {:can_read, Board.get_read_access_by_id(id, user_priority)},
         board_mapping <- BoardMapping.all(),
         board_moderators <- BoardModerator.all(),
         {:board, [_board]} <-
           {:board, Enum.filter(board_mapping, fn bm -> bm.board_id == id end)} do
      render(conn, :find, %{
        board_moderators: board_moderators,
        board_mapping: board_mapping,
        board_id: id,
        user_priority: user_priority
      })
    else
      # if user can't read board, return 404, user doesn't need to know hidden board exists
      {:can_read, {:ok, false}} ->
        ErrorHelpers.render_json_error(
          conn,
          404,
          "Board not found"
        )

      {:can_read, {:error, :board_does_not_exist}} ->
        ErrorHelpers.render_json_error(conn, 400, "Error, board does not exist")

      {:board, []} ->
        ErrorHelpers.render_json_error(conn, 400, "Error, board does not exist")

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot fetch boards")
    end
  end

  @doc """
  Used to retrieve `Board` movelist for moderators
  """
  def movelist(conn, _attrs) do
    with :ok <- ACL.allow!(conn, "boards.moveList"),
         user_priority <- ACL.get_user_priority(conn),
         movelist <- Board.movelist(user_priority) do
      render(conn, :movelist, %{movelist: movelist})
    else
      _ -> ErrorHelpers.render_json_error(conn, 400, "Error, cannot fetch board movelist")
    end
  end

  @doc """
  Used to convert `Board` slug to id
  """
  # TODO(akinsey): allow validate cast to match a regex, for completeness validate slug format
  def slug_to_id(conn, attrs) do
    with slug <- Validate.cast(attrs, "slug", :string, required: true),
         {:ok, id} <- Board.slug_to_id(slug) do
      render(conn, :slug_to_id, id: id)
    else
      {:error, :board_does_not_exist} ->
        ErrorHelpers.render_json_error(
          conn,
          400,
          "Error, cannot convert slug: board does not exist"
        )

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot convert board slug to id")
    end
  end

  defp check_proxy(conn, _) do
    conn =
      case conn.private.phoenix_action do
        :slug_to_id ->
          case Integer.parse(conn.params["slug"]) do
            {_, ""} ->
              slug_as_id = Validate.cast(conn.params, "slug", :integer, required: true)
              %{boards_seq: boards_seq} = Application.get_env(:epochtalk_server, :proxy_config)
              boards_seq = boards_seq |> String.to_integer()

              if slug_as_id < boards_seq do
                conn
                |> render(:slug_to_id, id: slug_as_id)
                |> halt()
              else
                conn
              end

            _ ->
              conn
          end

        :by_category ->
          conn
          |> proxy_by_category(conn.params)
          |> halt()

        _ ->
          conn
      end

    conn
  end

  defp proxy_by_category(conn, attrs) do
    with :ok <- ACL.allow!(conn, "boards.allCategories"),
         stripped <- Validate.cast(attrs, "stripped", :boolean, default: false),
         user_priority <- ACL.get_user_priority(conn),
         board_mapping <- BoardMapping.all(stripped: stripped),
         board_moderators <- BoardModerator.all(),
         {:ok, board_counts} <- ProxyConversion.build_model("boards.counts"),
         {:ok, board_last_post_info} <- ProxyConversion.build_model("boards.last_post_info"),
         categories <- Category.all() do
      render(conn, :proxy_by_category, %{
        categories: categories,
        board_moderators: board_moderators,
        board_mapping: board_mapping,
        user_priority: user_priority,
        board_counts: board_counts,
        board_last_post_info: board_last_post_info
      })
    else
      _ -> ErrorHelpers.render_json_error(conn, 400, "Error, cannot fetch boards")
    end
  end
end
