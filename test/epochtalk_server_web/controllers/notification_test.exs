defmodule Test.EpochtalkServerWeb.Controllers.Notification do
  use Test.Support.ConnCase, async: true
  import Test.Support.Factory

  @number_of_mentions 99

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
      build_list(@number_of_mentions, :mention, %{
        thread_id: thread_data.post.id,
        post_id: thread_data.post.thread_id,
        mentioner_id: user.id,
        mentionee_id: admin_user.id
      })

    {:ok, mentions_count: @number_of_mentions, mentions: mentions, thread_data: thread_data}
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
    test "when authenticated as notification receiver and notifications exceed max, returns max+",
         %{conn: conn, users: %{user: user, admin_user: admin_user}, thread_data: thread_data} do
      build(:mention, %{
        thread_id: thread_data.post.id,
        post_id: thread_data.post.thread_id,
        mentioner_id: user.id,
        mentionee_id: admin_user.id
      })
      response =
        conn
        |> get(Routes.notification_path(conn, :counts))
        |> json_response(200)

      assert response["mention"] == "#{@number_of_mentions}+"
      assert response["message"] == 0
    end

    @tag authenticated: :admin
    test "when authenticated as notification receiver and with max parameter set, returns correct number of notifications user has",
         %{conn: conn} do
      max_count = @number_of_mentions - 1

      response =
        conn
        |> get(Routes.notification_path(conn, :counts), %{max: max_count})
        |> json_response(200)

      assert response["mention"] == "#{max_count}+"
      assert response["message"] == 0
    end
  end

  describe "dismiss/2" do
    test "when unauthenticated", %{conn: conn} do
      response =
        conn
        |> get(Routes.notification_path(conn, :counts))
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
    end

    @tag authenticated: :admin
    test "when authenticated as notification receiver, after dismiss by type, returns correct number of notifications user has",
         %{conn: conn} do
      dismiss_response =
        conn
        |> post(Routes.notification_path(conn, :dismiss), %{"type" => "mention"})
        |> json_response(200)

      assert dismiss_response == %{"success" => true}

      response =
        conn
        |> get(Routes.notification_path(conn, :counts), %{})
        |> json_response(200)

      assert response["mention"] == 0
      assert response["message"] == 0
    end

    @tag authenticated: :admin
    test "when authenticated as notification receiver, after dismiss of incorrect type, returns correct number of notifications user has",
         %{conn: conn, mentions_count: mentions_count} do
      dismiss_response =
        conn
        |> post(Routes.notification_path(conn, :dismiss), %{"type" => "message"})
        |> json_response(200)

      assert dismiss_response == %{"success" => true}

      response =
        conn
        |> get(Routes.notification_path(conn, :counts), %{})
        |> json_response(200)

      assert response["mention"] == mentions_count
      assert response["message"] == 0
    end

    @tag authenticated: :admin
    test "when authenticated as notification receiver, after dismiss by mention id, returns correct number of notifications user has",
    %{conn: conn, mentions: mentions, mentions_count: mentions_count} do
      Enum.reduce(mentions, mentions_count, fn mention, count ->
        dismiss_response =
          conn
          |> post(Routes.notification_path(conn, :dismiss), %{"id" => mention.id})
          |> json_response(200)

        assert dismiss_response == %{"success" => true}

        response =
          conn
          |> get(Routes.notification_path(conn, :counts), %{})
          |> json_response(200)

        assert response["mention"] == count - 1
        assert response["message"] == 0
        count - 1
      end)
    end
  end
end
