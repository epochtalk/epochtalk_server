defmodule EpochtalkServerWeb.ThreadControllerTest do
  use EpochtalkServerWeb.ConnCase, async: false

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
      first_thread = normal_threads |> List.first()
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

    test "does not get threads for board that is above user priority (unauthenticated)", %{
      conn: conn
    } do
      admin_board_result =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: 2})
        |> json_response(403)

      super_admin_board_result =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: 3})
        |> json_response(403)

      assert %{"error" => "Forbidden"} = admin_board_result
      assert %{"message" => "Unauthorized, you do not have permission"} = admin_board_result
      assert %{"error" => "Forbidden"} = super_admin_board_result
      assert %{"message" => "Unauthorized, you do not have permission"} = super_admin_board_result
    end

    @tag :authenticated
    test "does not get threads for board that is above user priority (authenticated)", %{
      conn: conn
    } do
      admin_board_result =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: 2})
        |> json_response(403)

      super_admin_board_result =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: 3})
        |> json_response(403)

      assert %{"error" => "Forbidden"} = admin_board_result
      assert %{"message" => "Unauthorized, you do not have permission"} = admin_board_result
      assert %{"error" => "Forbidden"} = super_admin_board_result
      assert %{"message" => "Unauthorized, you do not have permission"} = super_admin_board_result
    end

    @tag authenticated: :admin
    test "gets threads for board that is within user priority", %{conn: conn} do
      result =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: 2})
        |> json_response(200)

      assert Map.has_key?(result, "normal") == true
      assert Map.has_key?(result, "sticky") == true
    end

    @tag authenticated: :admin
    test "gets threads for board that is at user priority", %{conn: conn} do
      result =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: 3})
        |> json_response(200)

      assert Map.has_key?(result, "normal") == true
      assert Map.has_key?(result, "sticky") == true
    end
  end
end
