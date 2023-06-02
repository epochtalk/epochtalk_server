defmodule EpochtalkServerWeb.ThreadControllerTest do
  use EpochtalkServerWeb.ConnCase, async: false
  alias EpochtalkServer.Models.Thread

  describe "by_board/2" do
    test "does not get threads for board that does not exist", %{conn: conn} do
      result =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: -1})
        |> json_response(400)

      assert %{"error" => "Bad Request"} = result
      assert %{"message" => "Read error, board does not exist"} = result
    end

    test "gets threads for a board that exists", %{conn: conn} do
      result =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: 1})
        |> json_response(200)

      assert Map.has_key?(result, "normal") == true
      assert Map.has_key?(result, "sticky") == true
    end
  end
end
