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
      {:board, []} -> ErrorHelpers.render_json_error(conn, 400, "Error, board does not exist")
      _ -> ErrorHelpers.render_json_error(conn, 400, "Error, cannot fetch boards")
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
end
