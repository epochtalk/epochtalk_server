defmodule Test.EpochtalkServerWeb.Controllers.Notification do
  use Test.Support.ConnCase, async: true
  import Test.Support.Factory
  alias EpochtalkServer.Models.Notification

  setup %{users: %{user: user, admin_user: admin_user}} do
    board = insert(:board)
    category = insert(:category)

    build(:board_mapping,
      attributes: [
        [category: category, view_order: 0],
        [board: board, category: category, view_order: 1]
      ]
    )

    [thread_data] = build_list(1, :thread, board: board, user: user)

    post_id = thread_data.post.id
    thread_id = thread_data.post.thread_id

    mention = build(:mention, %{
      thread_id: thread_id,
      post_id: post_id,
      mentioner_id: user.id,
      mentionee_id: admin_user.id
    })

    notification = %{
      "sender_id" => user.id,
      "receiver_id" => admin_user.id,
      "type" => "user",
      "data" => %{
        action: "refreshMentions",
        mention_id: mention.id
      }
    }

    # create notification associated with mention (for mentions dropdown)
    Notification.create(notification)
    :ok
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
    test "when authenticated as notification sender, returns correct number of notifications user has", %{conn: conn} do
      response =
        conn
        |> get(Routes.notification_path(conn, :counts))
        |> json_response(200)

      assert response["mention"] == 0
      assert response["message"] == 0
    end

    @tag authenticated: :admin
    test "when authenticated as notification receiver, returns correct number of notifications user has", %{conn: conn} do
      response =
        conn
        |> get(Routes.notification_path(conn, :counts))
        |> json_response(200)

      assert response["mention"] == 1
      assert response["message"] == 0
    end
  end
end
