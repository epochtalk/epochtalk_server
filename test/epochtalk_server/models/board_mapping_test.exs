defmodule Test.EpochtalkServer.Models.BoardMapping do
  use Test.Support.DataCase, async: true
  import Test.Support.Factory
  alias EpochtalkServer.Models.BoardMapping

  describe "all/1" do
    test "gets zero board mappings" do
      assert BoardMapping.all() |> Enum.count == 0
    end
    test "gets board mappings" do
      category = insert(:category)
      category_board1 = insert(:board)
      category_board2 = insert(:board)
      child_board1 = insert(:board)
      child_board2 = insert(:board)

      board_mapping_attrs = [
        %{
          id: category.id,
          name: category.name,
          type: "category",
          view_order: 0
        },
        %{
          id: category_board1.id,
          name: category_board1.name,
          type: "board",
          category_id: category.id,
          view_order: 1
        },
        %{
          id: category_board2.id,
          name: category_board2.name,
          type: "board",
          category_id: category.id,
          view_order: 2
        },
        %{
          id: child_board1.id,
          name: child_board1.name,
          type: "board",
          board_id: category_board1.id,
          view_order: 3
        },
        %{
          id: child_board2.id,
          name: child_board2.name,
          type: "board",
          board_id: category_board1.id,
          view_order: 4
        }
      ]
      BoardMapping.update(board_mapping_attrs)

      assert BoardMapping.all() |> Enum.count() == 4
    end
  end

  describe "update/1" do
    test "updates a board mapping" do
      category = insert(:category)
      board = insert(:board)
      initial_board_mappings_count = BoardMapping.all() |> Enum.count()

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

      assert BoardMapping.all() |> Enum.count() == 1
    end
  end

  describe "delete_board_by_id/1" do
    test "deletes a board mapping" do
      assert BoardMapping.all() |> Enum.count() == 0
      category = insert(:category)
      board = insert(:board)
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
      BoardMapping.update(board_mapping_attrs)
      assert BoardMapping.all() |> Enum.count() == 1

      BoardMapping.delete_board_by_id(board.id)
      assert BoardMapping.all() |> Enum.count() == 0
    end
  end
end
