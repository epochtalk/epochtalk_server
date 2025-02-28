defmodule Test.EpochtalkServer.Models.Mention do
  use Test.Support.ConnCase, async: true
  import Test.Support.Factory
  alias EpochtalkServer.Models.Mention

  setup %{users: %{user: user}} do
    category = build(:category)
    board = build(:board)

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
    test "given an empty user, errors", %{thread: thread} do
      attrs = %{
        "thread" => thread.id,
        "title" => "title",
        "body" => "(invalid)"
      }

      assert_raise FunctionClauseError,
                   ~r/no function clause matching/,
                   fn ->
                     Mention.username_to_user_id(%{id: nil, roles: nil}, attrs)
                  end
    end

    test "given an invalid thread id, succeeds", %{users: %{user: user}} do
      attrs = %{
        "thread" => -1,
        "title" => "title",
        "body" => "(invalid)"
      }

      result = Mention.username_to_user_id(user, attrs)
      assert result["body"] == attrs["body"]
      assert result["body_original"] == attrs["body"]
      assert result["mentioned_ids"] == []
    end

    test "given an empty title, succeeds", %{thread: thread, users: %{user: user}} do
      attrs = %{
        "thread" => thread.id,
        "title" => "",
        "body" => "body"
      }

      result = Mention.username_to_user_id(user, attrs)
      assert result["body"] == attrs["body"]
      assert result["body_original"] == attrs["body"]
      assert result["mentioned_ids"] == []
    end

    test "given an empty body, succeeds", %{thread: thread, users: %{user: user}} do
      attrs = %{
        "thread" => thread.id,
        "title" => "title",
        "body" => ""
      }

      result = Mention.username_to_user_id(user, attrs)
      assert result["body"] == attrs["body"]
      assert result["body_original"] == attrs["body"]
      assert result["mentioned_ids"] == []
    end

    test "given a user without acl permission, errors", %{
      thread: thread,
      users: %{private_user: user}
    } do
      attrs = %{
        "thread" => thread.id,
        "title" => "title",
        "body" => ""
      }

      assert_raise EpochtalkServerWeb.CustomErrors.InvalidPermission,
                   ~r/Forbidden, invalid permissions to perform this action/,
                   fn ->
                     Mention.username_to_user_id(user, attrs)
                   end
    end

    test "given a body with invalid mentions, does not generate mentions", %{
      thread: thread,
      users: %{user: user}
    } do
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

    test "given a body with valid mentions, generates unique mentions", %{
      thread: thread,
      users: %{user: user, admin_user: admin_user, super_admin_user: super_admin_user}
    } do
      attrs = %{
        "thread" => thread.id,
        "title" => "title",
        "body" => """
        @#{admin_user.username} this post should mention three users @#{user.username}
        @#{super_admin_user.username}, followed by invalids @not_valid @no_user
        hello admin!  (duplicate mention) @#{admin_user.username} @mentions
        """
      }

      expected_body = """
      {@#{admin_user.id}} this post should mention three users {@#{user.id}}
      {@#{super_admin_user.id}}, followed by invalids @not_valid @no_user
      hello admin!  (duplicate mention) {@#{admin_user.id}} @mentions
      """

      result = Mention.username_to_user_id(user, attrs)
      assert result["body_original"] == attrs["body"]
      assert result["body"] == expected_body

      assert Enum.sort(result["mentioned_ids"]) ==
               Enum.sort([user.id, admin_user.id, super_admin_user.id])
    end
  end
end
