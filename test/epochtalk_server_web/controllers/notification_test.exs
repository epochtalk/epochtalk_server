defmodule Test.EpochtalkServerWeb.Controllers.Notification do
  use Test.Support.ConnCase, async: false
  import Test.Support.Factory

  setup %{users: %{user: user, admin_user: admin_user}} do
    board = insert(:board)
    category = insert(:category)

    build(:board_mapping,
      attributes: [
        [category: category, view_order: 0],
        [board: board, category: category, view_order: 1]
      ]
    )

    thread_data = build(:thread, board: board, user: user)

    mentions =
      build_list(2, :mention, %{
        thread_id: thread_data.post.id,
        post_id: thread_data.post.thread_id,
        mentioner_id: user.id,
        mentionee_id: admin_user.id
      })

    Enum.each(mentions, fn mention ->
      build(:notification, %{
        mention_id: mention.id,
        type: "user",
        action: "refreshMentions",
        sender_id: user.id,
        receiver_id: admin_user.id
      })
    end)

    {:ok, mentions_count: Enum.count(mentions)}
  end

  describe "counts/2" do
    test "when unauthenticated, returns Unauthorized error", %{conn: conn} do
      response =
        conn
        |> get(Routes.notification_path(conn, :counts))
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
    end

    @tag :authenticated
    test "when authenticated as notification sender, returns correct number of notifications user has",
         %{conn: conn} do
      response =
        conn
        |> get(Routes.notification_path(conn, :counts))
        |> json_response(200)

      assert response["mention"] == 0
      assert response["message"] == 0
    end

    @tag authenticated: :admin
    test "when authenticated as notification receiver, returns correct number of notifications user has",
         %{conn: conn, mentions_count: mentions_count} do
      response =
        conn
        |> get(Routes.notification_path(conn, :counts))
        |> json_response(200)

      assert response["mention"] == mentions_count
      assert response["message"] == 0
    end

    @tag authenticated: :admin
    test "when authenticated as notification receiver and with max parameter set, returns correct number of notifications user has",
         %{conn: conn} do
      max_count = 1

      response =
        conn
        |> get(Routes.notification_path(conn, :counts), %{max: max_count})
        |> json_response(200)

      assert response["mention"] == "#{max_count}+"
      assert response["message"] == 0
    end
  end
end
