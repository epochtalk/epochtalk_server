defmodule Test.EpochtalkServer.Models.BoardMapping do
  use Test.Support.DataCase, async: true
  import Test.Support.Factory
  alias EpochtalkServer.Models.BoardMapping

  describe "all/1" do
    test "gets zero board mappings" do
      assert BoardMapping.all() |> Enum.count() == 0
    end

    test "gets board mappings" do
      category = build(:category)
      category_board1 = build(:board)
      category_board2 = build(:board)
      child_board1 = build(:board)
      child_board2 = build(:board)

      build(:board_mapping,
        attributes: [
          [category: category, view_order: 0],
          [board: category_board1, category: category, view_order: 1],
          [board: category_board2, category: category, view_order: 2],
          [board: child_board1, parent: category_board1, view_order: 3],
          [board: child_board2, parent: category_board1, view_order: 4]
        ]
      )

      board_mappings = BoardMapping.all()
      assert board_mappings |> Enum.count() == 4

      # test first board
      [board_mapping | board_mappings] = board_mappings
      assert board_mapping.board_id == category_board1.id
      assert board_mapping.category_id == category.id
      assert board_mapping.parent_id == nil
      assert board_mapping.view_order == 1
      assert board_mapping.board == category_board1

      # test second board
      [board_mapping | board_mappings] = board_mappings
      assert board_mapping.board_id == category_board2.id
      assert board_mapping.category_id == category.id
      assert board_mapping.parent_id == nil
      assert board_mapping.view_order == 2
      assert board_mapping.board == category_board2

      # test third board
      [board_mapping | board_mappings] = board_mappings
      assert board_mapping.board_id == child_board1.id
      assert board_mapping.category_id == nil
      assert board_mapping.parent_id == category_board1.id
      assert board_mapping.view_order == 3
      assert board_mapping.board == child_board1

      # test fourth board
      [board_mapping | board_mappings] = board_mappings
      assert board_mapping.board_id == child_board2.id
      assert board_mapping.category_id == nil
      assert board_mapping.parent_id == category_board1.id
      assert board_mapping.view_order == 4
      assert board_mapping.board == child_board2

      assert board_mappings == []
    end
  end

  describe "update/1" do
    test "updates a board mapping" do
      category = build(:category)
      board = build(:board)

      result =
        build(:board_mapping,
          attributes: [
            [category: category, view_order: 0],
            [board: board, category: category, view_order: 1]
          ]
        )

      assert result == {:ok, :ok}

      assert BoardMapping.all() |> Enum.count() == 1
    end
  end

  describe "delete_board_by_id/1" do
    test "deletes a board mapping" do
      assert BoardMapping.all() |> Enum.count() == 0

      category = build(:category)
      board = build(:board)

      build(:board_mapping,
        attributes: [
          [category: category, view_order: 0],
          [board: board, category: category, view_order: 1]
        ]
      )

      assert BoardMapping.all() |> Enum.count() == 1

      BoardMapping.delete_board_by_id(board.id)
      assert BoardMapping.all() |> Enum.count() == 0
    end
  end
end
