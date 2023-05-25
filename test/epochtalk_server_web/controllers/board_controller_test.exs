defmodule EpochtalkServerWeb.BoardControllerTest do
  use EpochtalkServerWeb.ConnCase, async: false
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Repo

  describe "find/2" do
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

    test "does not find a board that doesn't exit", %{conn: conn} do
      result = conn
      |> get(Routes.board_path(conn, :find, 0))
      |> json_response(400)
      assert %{"error" => "Bad Request"} = result
      assert %{"message" => "Error, board does not exist"} = result
    end
  end
end
