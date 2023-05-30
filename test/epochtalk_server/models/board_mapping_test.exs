defmodule EpochtalkServer.BoardMappingTest do
  use EpochtalkServer.DataCase, async: false
  alias EpochtalkServer.Models.Category
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.BoardMapping

  setup _context do
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

    {:ok,
     board: board,
     board_attrs: board_attrs,
     category: category,
     category_attrs: category_attrs}
  end

  describe "all/1" do
    test "gets all board mappings" do
      result = BoardMapping.all()
      assert Enum.count(result) == 1
    end
  end

  describe "update/1" do
    test "updates a board mapping", %{category: category, board: board} do
      board_mapping_attrs = [
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

      result = BoardMapping.update(board_mapping_attrs)
      assert result == {:ok, :ok}

      board_mappings_count = BoardMapping.all() |> Enum.count
      assert board_mappings_count == 2
    end
  end
end
