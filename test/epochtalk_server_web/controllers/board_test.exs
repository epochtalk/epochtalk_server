defmodule Test.EpochtalkServerWeb.Controllers.Board do
  use Test.Support.ConnCase, async: true
  import Test.Support.Factory
  alias EpochtalkServerWeb.CustomErrors.InvalidPermission

  setup %{conn: conn} do
    category = insert(:category)
    parent_board = insert(:board)
    child_board = insert(:board)
    admin_board = insert(:board, viewable_by: 1)
    super_admin_board = insert(:board, viewable_by: 0)

    build(:board_mapping,
      attributes: [
        [category: category, view_order: 1],
        [board: parent_board, category: category, view_order: 1],
        [board: child_board, parent: parent_board, view_order: 1],
        [board: admin_board, category: category, view_order: 2],
        [board: super_admin_board, category: category, view_order: 3]
      ]
    )

    {:ok, conn: conn, parent_board: parent_board, child_board: child_board, category: category, admin_board: admin_board, super_admin_board: super_admin_board}
  end

  describe "by_category/2" do
    test "finds all active boards", %{
      conn: conn,
      category: category,
      parent_board: parent_board,
      child_board: child_board
    } do
      response =
        conn
        |> get(Routes.board_path(conn, :by_category))
        |> json_response(200)
        |> case do
          %{"boards" => boards} -> boards
        end

      # check number of categories
      assert Enum.count(response) == 1
      seeded_category = response |> Enum.at(0)

      # check number of boards under category
      assert seeded_category |> Map.get("boards") |> Enum.count() == 3

      # extract category/board info
      %{
        "id" => response_category_id,
        "name" => response_category_name,
        "view_order" => response_category_view_order,
        "boards" => response_boards
      } = response |> Enum.at(0)

      # check category/board info
      assert response_category_id == category.id
      assert response_category_name == category.name
      assert response_category_view_order == 1

      # extract parent board
      [response_parent_board | response_boards] = response_boards
      assert response_boards |> Enum.count() == 2

      # check parent board
      assert response_parent_board["id"] == parent_board.id
      assert response_parent_board["name"] == parent_board.name
      assert response_parent_board["category_id"] == category.id
      assert response_parent_board["parent_id"] == nil
      assert response_parent_board["children"] |> Enum.count() == 1
      assert response_parent_board["description"] == parent_board.description
      assert response_parent_board["view_order"] == 1
      assert response_parent_board["slug"] == parent_board.slug
      assert response_parent_board["viewable_by"] == parent_board.viewable_by
      assert response_parent_board["postable_by"] == parent_board.postable_by
      assert response_parent_board["right_to_left"] == parent_board.right_to_left

      assert response_parent_board["meta"]["disable_self_mod"] ==
               parent_board.meta["disable_self_mod"]

      assert response_parent_board["meta"]["disable_post_edit"] ==
               parent_board.meta["disable_post_edit"]

      assert response_parent_board["meta"]["disable_signature"] ==
               parent_board.meta["disable_signature"]

      # extract child board
      response_parent_board_children = response_parent_board["children"]
      [response_child_board | response_parent_board_children] = response_parent_board_children
      assert response_parent_board_children == []

      # check child board
      assert response_child_board["id"] == child_board.id
      assert response_child_board["name"] == child_board.name
      assert response_child_board["category_id"] == nil
      assert response_child_board["parent_id"] == parent_board.id
      assert response_child_board["children"] |> Enum.count() == 0
      assert response_child_board["description"] == child_board.description
      assert response_child_board["view_order"] == 1
      assert response_child_board["slug"] == child_board.slug
      assert response_child_board["viewable_by"] == child_board.viewable_by
      assert response_child_board["postable_by"] == child_board.postable_by
      assert response_child_board["right_to_left"] == child_board.right_to_left

      assert response_child_board["meta"]["disable_self_mod"] ==
               child_board.meta["disable_self_mod"]

      assert response_child_board["meta"]["disable_post_edit"] ==
               child_board.meta["disable_post_edit"]

      assert response_child_board["meta"]["disable_signature"] ==
               child_board.meta["disable_signature"]
    end
  end

  describe "find/2" do
    test "given a nonexistant id, does not find a board", %{conn: conn} do
      response =
        conn
        |> get(Routes.board_path(conn, :find, 0))
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, board does not exist"
    end

    test "given an existing id, finds a board", %{conn: conn, parent_board: board} do
      response =
        conn
        |> get(Routes.board_path(conn, :find, board.id))
        |> json_response(200)

      assert response["name"] == board.name
      assert response["slug"] == board.slug
      assert response["description"] == board.description
      assert response["viewable_by"] == board.viewable_by
      assert response["postable_by"] == board.postable_by
      assert response["right_to_left"] == board.right_to_left
      assert response["disable_self_mod"] == board.meta["disable_self_mod"]
      assert response["disable_post_edit"] == board.meta["disable_post_edit"]
      assert response["disable_signature"] == board.meta["disable_signature"]
    end
  end

  describe "slug_to_id/2" do
    test "given a nonexistant slug, does not deslugify board id", %{conn: conn} do
      response =
        conn
        |> get(Routes.board_path(conn, :slug_to_id, "bad-slug"))
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, cannot convert slug: board does not exist"
    end

    test "given an existing slug, deslugifies board id", %{conn: conn, parent_board: board} do
      response =
        conn
        |> get(Routes.board_path(conn, :slug_to_id, board.slug))
        |> json_response(200)

      assert response["id"] == board.id
    end
  end

  describe "movelist/2" do
    test "when unauthenticated, returns InvalidPermission error", %{conn: conn} do
      response_boards =
        conn
        |> get(Routes.board_path(conn, :movelist))
        |> json_response(401)

      assert response_boards["error"] == "Unauthorized"
      assert response_boards["message"] == "No resource found"
    end

    @tag :authenticated
    test "when authenticated with invalid permissions, returns InvalidPermission error", %{conn: conn} do
      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                      get(conn, Routes.board_path(conn, :movelist))
                   end
    end

    @tag authenticated: :admin
    test "when authenticated as admin user, returns movelist with viewable boards", %{conn: conn, admin_board: admin_board, super_admin_board: super_admin_board} do
      response_boards =
        conn
        |> get(Routes.board_path(conn, :movelist))
        |> json_response(200)

      assert response_boards |> Enum.count() == 3

      response_parent_board = Enum.at(response_boards, 0)
      response_child_board = Enum.at(response_boards, 1)
      response_admin_board = Enum.at(response_boards, 2)

      assert response_parent_board["id"] != super_admin_board.id
      assert response_child_board["id"] != super_admin_board.id

      assert response_admin_board["viewable_by"] == admin_board.viewable_by
      assert response_admin_board["id"] == admin_board.id
      assert response_admin_board["id"] != super_admin_board.id
    end

    @tag authenticated: :super_admin
    test "when authenticated as super admin user, returns movelist with viewable boards", %{conn: conn, admin_board: admin_board, super_admin_board: super_admin_board} do
      response_boards =
        conn
        |> get(Routes.board_path(conn, :movelist))
        |> json_response(200)

      assert response_boards |> Enum.count() == 4

      response_parent_board = Enum.at(response_boards, 0)
      response_child_board = Enum.at(response_boards, 1)
      response_admin_board = Enum.at(response_boards, 2)
      response_super_admin_board = Enum.at(response_boards, 3)

      assert response_parent_board["id"] != super_admin_board.id
      assert response_child_board["id"] != super_admin_board.id

      assert response_admin_board["viewable_by"] == admin_board.viewable_by
      assert response_admin_board["id"] == admin_board.id

      assert response_super_admin_board["viewable_by"] == super_admin_board.viewable_by
      assert response_super_admin_board["id"] == super_admin_board.id
    end
  end
end
