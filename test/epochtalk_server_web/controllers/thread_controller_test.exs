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

      normal_threads = result["normal"]
      first_thread = normal_threads |> List.first
      assert Map.has_key?(first_thread, "created_at") == true
      assert Map.has_key?(first_thread, "id") == true
      assert Map.has_key?(first_thread, "last_post_avatar") == true
      assert Map.has_key?(first_thread, "last_post_created_at") == true
      assert Map.has_key?(first_thread, "last_post_id") == true
      assert Map.has_key?(first_thread, "last_post_position") == true
      assert Map.has_key?(first_thread, "last_post_username") == true
      assert Map.has_key?(first_thread, "locked") == true
      assert Map.has_key?(first_thread, "moderated") == true
      assert Map.has_key?(first_thread, "poll") == true
      assert Map.has_key?(first_thread, "post_count") == true
      assert Map.has_key?(first_thread, "slug") == true
      assert Map.has_key?(first_thread, "sticky") == true
      assert Map.has_key?(first_thread, "title") == true
      assert Map.has_key?(first_thread, "updated_at") == true
      assert Map.has_key?(first_thread, "user") == true
      assert Map.has_key?(first_thread, "view_count") == true

      assert Map.get(first_thread, "locked") == false
      assert Map.get(first_thread, "moderated") == false
      assert Map.get(first_thread, "slug") == "test_slug"
      assert Map.get(first_thread, "sticky") == false
      assert Map.get(first_thread, "title") == "test"
    end
  end
end
