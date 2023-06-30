defmodule Test.EpochtalkServerWeb.Controllers.Board do
  use Test.Support.ConnCase, async: true
  import Test.Support.Factory
  alias EpochtalkServer.Models.BoardMapping

  setup %{conn: conn} do
    category = insert(:category)
    board = insert(:board, [
      viewable_by: 10,
      postable_by: 10,
      right_to_left: false
    ])

    # create board mapping for testing
    board_mapping = [
      %{
        id: category.id,
        name: category.name,
        type: "category",
        view_order: 0
      },
      %{
        id: board.id,
        name: board.name,
        type: "board",
        category_id: category.id,
        view_order: 1
      }
    ]

    BoardMapping.update(board_mapping)

    {:ok, conn: conn, board: board, category: category}
  end

  describe "by_category/2" do
    test "finds all active boards", %{conn: conn, category: category, board: board} do
      response =
        conn
        |> get(Routes.board_path(conn, :by_category))
        |> json_response(200)
        |> case do
          %{"boards" => boards} -> boards
        end

      # two categories: one from seed, one from setup
      assert Enum.count(response) == 2

      # check seeded category boards
      seeded_category = response |> Enum.at(0)
      assert seeded_category |> Map.get("boards") |> Enum.count() > 0

      # setup category
      %{
        "id" => response_category_id,
        "name" => response_category_name,
        "view_order" => response_category_view_order,
        "boards" => [
          %{
            "id" => response_board_id,
            "board_id" => response_board_board_id,
            "name" => response_board_name,
            "category_id" => response_board_category_id,
            "children" => response_board_children,
            "description" => response_board_description,
            "view_order" => response_board_view_order,
            "slug" => response_board_slug,
            "viewable_by" => response_board_viewable_by,
            "postable_by" => response_board_postable_by,
            "right_to_left" => response_board_right_to_left
          }
        ]
      } = response |> Enum.at(1)

      assert response_category_id == category.id
      assert response_category_name == category.name
      assert response_category_view_order == 0
      assert response_board_id == board.id
      assert response_board_board_id == board.id
      assert response_board_name == board.name
      assert response_board_category_id == category.id
      assert response_board_children |> Enum.count() == 0
      assert response_board_description == board.description
      assert response_board_name == board.name
      assert response_board_view_order == 1
      assert response_board_slug == board.slug
      assert response_board_viewable_by == board.viewable_by
      assert response_board_postable_by == board.postable_by
      assert response_board_right_to_left == board.right_to_left
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

    test "given an existing id, finds a board", %{conn: conn, board: board} do
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

    test "given an existing slug, deslugifies board id", %{conn: conn, board: board} do
      response =
        conn
        |> get(Routes.board_path(conn, :slug_to_id, board.slug))
        |> json_response(200)

      assert response["id"] == board.id
    end
  end
end
