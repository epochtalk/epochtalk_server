defmodule Test.EpochtalkServer.Models.Board do
  use Test.Support.DataCase, async: true
  alias EpochtalkServer.Models.Board

  describe "create/1" do
    test "with invalid parameters, does not create a board", _ do
      assert_raise BadMapError,
                   ~r/^expected a map, got: ""/,
                   fn ->
                     Board.create("")
                   end
    end

    test "with valid parameters, creates a board", _ do
      board = %{
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

      {:ok, new_board} = Board.create(board)
      assert new_board.name == board.name
      assert new_board.slug == board.slug
      assert new_board.description == board.description
      assert new_board.viewable_by == board.viewable_by
      assert new_board.postable_by == board.postable_by
      assert new_board.right_to_left == board.right_to_left
      assert new_board.meta == board.meta
    end
  end
end
