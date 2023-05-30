defmodule EpochtalkServerWeb.BoardControllerTest do
  use EpochtalkServerWeb.ConnCase, async: false
  alias EpochtalkServer.Models.Category
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.BoardMapping

  setup %{conn: conn} do
    # create category for testing
    category_attrs = %{
      name: "test category"
    }

    {:ok, category} = Category.create(category_attrs)

    # create board for testing
    board_attrs = %{
      name: "test board",
      slug: "test-board",
      description: "test board description",
      viewable_by: 10,
      postable_by: 10,
      right_to_left: false
    }

    {:ok, board} = Board.create(board_attrs)

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

    {:ok,
     conn: conn,
     board: board,
     board_attrs: board_attrs,
     category: category,
     category_attrs: category_attrs}
  end

  describe "by_category/2" do
    test "finds all active boards", %{conn: conn} do
      result =
        conn
        |> get(Routes.board_path(conn, :by_category))
        |> json_response(200)
        |> case do
          %{"boards" => boards} -> boards
        end

      # two boards: one from seed, one from setup
      assert Enum.count(result) == 2
    end
  end

  describe "find/2" do
    test "does not find a board that doesn't exit", %{conn: conn} do
      result =
        conn
        |> get(Routes.board_path(conn, :find, 0))
        |> json_response(400)

      assert %{"error" => "Bad Request"} = result
      assert %{"message" => "Error, board does not exist"} = result
    end

    test "finds a board that exits", %{conn: conn, board: board} do
      result =
        conn
        |> get(Routes.board_path(conn, :find, board.id))
        |> json_response(200)

      assert result["name"] == board.name
      assert result["slug"] == board.slug
      assert result["description"] == board.description
      assert result["viewable_by"] == board.viewable_by
      assert result["postable_by"] == board.postable_by
      assert result["right_to_left"] == board.right_to_left
    end
  end

  describe "slug_to_id/2" do
    test "does not deslugify a board that doesn't exit", %{conn: conn} do
      result =
        conn
        |> get(Routes.board_path(conn, :slug_to_id, "bad-slug"))
        |> json_response(400)

      assert %{"error" => "Bad Request"} = result
      assert %{"message" => "Error, cannot board does not exist"} = result
    end

    test "deslugifies a board that exits", %{conn: conn, board: board} do
      result =
        conn
        |> get(Routes.board_path(conn, :slug_to_id, board.slug))
        |> json_response(200)

      assert result["id"] == board.id
    end
  end
end
