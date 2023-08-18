defmodule Test.EpochtalkServerWeb.Controllers.Thread do
  use Test.Support.ConnCase, async: true
  import Test.Support.Factory

  setup %{users: %{user: user, admin_user: admin_user, super_admin_user: super_admin_user}} do
    board = insert(:board)
    admin_board = insert(:board, viewable_by: 1)
    super_admin_board = insert(:board, viewable_by: 0)
    category = insert(:category)

    build(:board_mapping,
      attributes: [
        [category: category, view_order: 0],
        [board: board, category: category, view_order: 1],
        [board: admin_board, category: category, view_order: 2],
        [board: super_admin_board, category: category, view_order: 3]
      ]
    )

    threads = build_list(3, :thread, board: board, user: user)
    admin_threads = build_list(3, :thread, board: admin_board, user: admin_user)
    super_admin_threads = build_list(3, :thread, board: super_admin_board, user: super_admin_user)

    {
      :ok,
      board: board,
      admin_board: admin_board,
      super_admin_board: super_admin_board,
      threads: threads,
      admin_threads: admin_threads,
      super_admin_threads: super_admin_threads
    }
  end

  describe "by_board/2" do
    test "given an id for nonexistant board, does not get threads", %{conn: conn} do
      response =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: -1})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Read error, board does not exist"
    end

    test "given an id for existing board, gets threads", %{
      conn: conn,
      board: board,
      threads: factory_threads
    } do
      response =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: board.id})
        |> json_response(200)

      assert Map.has_key?(response, "normal") == true
      assert Map.has_key?(response, "sticky") == true

      # check thread keys
      normal_threads = response["normal"]
      first_thread = normal_threads |> List.first()
      assert Map.has_key?(first_thread, "created_at") == true
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

      # compare to factory results
      factory_threads = factory_threads |> Enum.sort(&(&1.post.thread.id < &2.post.thread.id))
      normal_threads = normal_threads |> Enum.sort(&(Map.get(&1, "id") < Map.get(&2, "id")))

      Enum.zip(normal_threads, factory_threads)
      |> Enum.each(fn {normal_thread, factory_thread} ->
        factory_thread_attributes = factory_thread.attributes
        assert Map.get(normal_thread, "id") == factory_thread.post.thread.id
        assert Map.get(normal_thread, "locked") == Map.get(factory_thread_attributes, "locked")

        assert Map.get(normal_thread, "moderated") ==
                 Map.get(normal_thread, "moderated")

        assert Map.get(normal_thread, "slug") == Map.get(factory_thread_attributes, "slug")
        assert Map.get(normal_thread, "sticky") == Map.get(factory_thread_attributes, "sticky")
        assert Map.get(normal_thread, "title") == Map.get(factory_thread_attributes, "title")
      end)
    end

    test "given an id for board above unauthenticated user priority, does not get threads", %{
      conn: conn,
      admin_board: admin_board,
      super_admin_board: super_admin_board
    } do
      admin_board_response =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: admin_board.id})
        |> json_response(403)

      super_admin_board_response =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: super_admin_board.id})
        |> json_response(403)

      assert admin_board_response["error"] == "Forbidden"
      assert admin_board_response["message"] == "Unauthorized, you do not have permission"
      assert super_admin_board_response["error"] == "Forbidden"
      assert super_admin_board_response["message"] == "Unauthorized, you do not have permission"
    end

    @tag :authenticated
    test "given an id for board above authenticated user priority, does not get threads", %{
      conn: conn,
      admin_board: admin_board,
      super_admin_board: super_admin_board
    } do
      admin_board_response =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: admin_board.id})
        |> json_response(403)

      super_admin_board_response =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: super_admin_board.id})
        |> json_response(403)

      assert admin_board_response["error"] == "Forbidden"
      assert admin_board_response["message"] == "Unauthorized, you do not have permission"
      assert super_admin_board_response["error"] == "Forbidden"
      assert super_admin_board_response["message"] == "Unauthorized, you do not have permission"
    end

    @tag authenticated: :admin
    test "given an id for board at authenticated user priority (admin), gets threads", %{
      conn: conn,
      admin_board: admin_board
    } do
      response =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: admin_board.id})
        |> json_response(200)

      assert Map.has_key?(response, "normal") == true
      assert Map.has_key?(response, "sticky") == true
    end

    @tag authenticated: :super_admin
    test "given an id for board within authenticated user priority (super_admin), gets threads",
         %{
           conn: conn,
           admin_board: admin_board
         } do
      response =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: admin_board.id})
        |> json_response(200)

      assert Map.has_key?(response, "normal") == true
      assert Map.has_key?(response, "sticky") == true
    end

    @tag authenticated: :super_admin
    test "given an id for board at authenticated user priority (super_admin), gets threads", %{
      conn: conn,
      super_admin_board: super_admin_board
    } do
      response =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: super_admin_board.id})
        |> json_response(200)

      assert Map.has_key?(response, "normal") == true
      assert Map.has_key?(response, "sticky") == true
    end
  end
end
