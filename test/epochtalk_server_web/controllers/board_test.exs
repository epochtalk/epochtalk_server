defmodule Test.EpochtalkServerWeb.Controllers.Board do
  use Test.Support.ConnCase, async: true
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
      right_to_left: false,
      meta: %{
        disable_self_mod: false,
        disable_post_edit: nil,
        disable_signature: false
      }
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
            "right_to_left" => response_board_right_to_left,
            "meta" => %{
              "disable_self_mod" => response_board_meta_disable_self_mod,
              "disable_post_edit" => response_board_meta_disable_post_edit,
              "disable_signature" => response_board_meta_disable_signature
            }
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
      assert response_board_meta_disable_self_mod == board.meta.disable_self_mod
      assert response_board_meta_disable_post_edit == board.meta.disable_post_edit
      assert response_board_meta_disable_signature == board.meta.disable_signature
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
      assert response["disable_self_mod"] == board.meta.disable_self_mod
      assert response["disable_post_edit"] == board.meta.disable_post_edit
      assert response["disable_signature"] == board.meta.disable_signature
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
