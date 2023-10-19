defmodule Test.EpochtalkServer.Models.Mention do
  use Test.Support.ConnCase, async: true
  import Test.Support.Factory
  alias EpochtalkServer.Models.Mention

  setup %{users: %{user: user}} do
    category = insert(:category)
    board = insert(:board)
    build(:board_mapping,
      attributes: [
        [category: category, view_order: 0],
        [board: board, category: category, view_order: 1]
      ]
    )
    thread = build(:thread, board: board, user: user)
    {:ok, thread: thread.post.thread}
  end

  describe "username_to_user_id/2" do
    test "given a body with invalid mentions, does not generate mentions", %{thread: thread, users: %{user: user}} do
      attrs = %{
        "thread" => thread.id,
        "title" => "title",
        "body" => """
        @invalid @not_valid @no_user
        this post should not @generate @ny @mentions
        """
      }
      result = Mention.username_to_user_id(user, attrs)
      assert result["body"] == attrs["body"]
      assert result["body_original"] == attrs["body"]
      assert result["mentioned_ids"] == []
    end
  end
end