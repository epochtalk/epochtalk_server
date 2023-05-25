defmodule EpochtalkServerWeb.BoardTest do
  use EpochtalkServer.DataCase, async: false
  alias EpochtalkServer.Models.Board

  describe "create/1" do
    test "does not create a board with invalid parameters", _ do
      assert_raise BadMapError,
                   ~r/^expected a map, got: ""/,
                   fn ->
                     Board.create("")
                   end
    end
    test "creates a board with valid parameters", _ do
      board = %{
        name: "test board",
        slug: "test-board",
        description: "test board description",
        viewable_by: 10,
        postable_by: 10,
        right_to_left: false
      }
      Board.create(board)
    end
  end
end
