defmodule EpochtalkServerWeb.BoardControllerTest do
  use EpochtalkServerWeb.ConnCase, async: false
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Repo

  setup %{conn: conn} do
    # create board for testing
    board = %{
      name: "test board",
      slug: "test-board",
      description: "test board description",
      viewable_by: 10,
      postable_by: 10,
      right_to_left: false
    }
    {:ok, new_board} = Board.create(board)
    {:ok, conn: conn, board: new_board, board_attrs: board}
  end

  describe "find/2" do
    test "does not find a board that doesn't exit", %{conn: conn} do
      result = conn
      |> get(Routes.board_path(conn, :find, 0))
      |> json_response(400)
      assert %{"error" => "Bad Request"} = result
      assert %{"message" => "Error, board does not exist"} = result
    end

    test "finds a board that exits", %{conn: conn, board: board} do
      result = conn
      |> get(Routes.board_path(conn, :find, board.id))
      |> json_response(200)
      assert result["name"] == board["name"]
      assert result["slug"] == board["slug"]
      assert result["description"] == board["description"]
      assert result["viewable_by"] == board["viewable_by"]
      assert result["postable_by"] == board["postable_by"]
      assert result["right_to_left"] == board["right_to_left"]
    end
  end

  describe "slug_to_id/2" do
    test "does not deslugify a board that doesn't exit", %{conn: conn} do
      result = conn
      |> get(Routes.board_path(conn, :slug_to_id, "bad-slug"))
      |> json_response(400)
      assert %{"error" => "Bad Request"} = result
      assert %{"message" => "Error, cannot board does not exist"} = result
    end

    test "deslugifies a board that exits", %{conn: conn, board: board} do
      result = conn
      |> get(Routes.board_path(conn, :slug_to_id, board.slug))
      |> json_response(200)
      assert result["id"] == board.id
    end
  end
end
