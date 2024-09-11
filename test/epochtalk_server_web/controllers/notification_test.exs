defmodule Test.EpochtalkServerWeb.Controllers.Notification do
  use Test.Support.ConnCase, async: true
  import Test.Support.Factory

  @mentions_count 99

  setup %{users: %{user: user, admin_user: admin_user}} do
    board = build(:board)
    category = build(:category)

    build(:board_mapping,
      attributes: [
        [category: category, view_order: 0],
        [board: board, category: category, view_order: 1]
      ]
    )

    thread_data = build(:thread, board: board, user: user)

    mentions =
      build_list(@mentions_count, :mention, %{
        thread_id: thread_data.post.thread_id,
        post_id: thread_data.post.id,
        mentioner_id: user.id,
        mentionee_id: admin_user.id
      })

    {:ok, mentions: mentions, thread_data: thread_data}
  end

  describe "counts/2" do
    test "when unauthenticated, returns Unauthorized error", %{conn: conn} do
      response =
        conn
        |> get(~p"/api/notifications/counts")
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
    end

    @tag :authenticated
    test "when authenticated as notification sender with no notifications, returns no mentions",
         %{conn: conn} do
      response =
        conn
        |> get(~p"/api/notifications/counts")
        |> json_response(200)

      assert response["mention"] == 0
      assert response["message"] == 0
    end

    @tag authenticated: :admin
    test "when authenticated as notification receiver, returns mentions count",
         %{conn: conn} do
      response =
        conn
        |> get(~p"/api/notifications/counts")
        |> json_response(200)

      assert response["mention"] == @mentions_count
      assert response["message"] == 0
    end

    @tag authenticated: :admin
    test "when authenticated as notification receiver and notifications exceed default max, returns max+",
         %{conn: conn, users: %{user: user, admin_user: admin_user}, thread_data: thread_data} do
      build(:mention, %{
        thread_id: thread_data.post.thread_id,
        post_id: thread_data.post.id,
        mentioner_id: user.id,
        mentionee_id: admin_user.id
      })

      response =
        conn
        |> get(~p"/api/notifications/counts")
        |> json_response(200)

      assert response["mention"] == "#{@mentions_count}+"
      assert response["message"] == 0
    end

    @tag authenticated: :admin
    test "when authenticated as notification receiver with max parameter set and notifications exceed max, returns max+",
         %{conn: conn} do
      max_count = @mentions_count - 1

      response =
        conn
        |> get(~p"/api/notifications/counts", %{max: max_count})
        |> json_response(200)

      assert response["mention"] == "#{max_count}+"
      assert response["message"] == 0
    end
  end

  describe "dismiss/2" do
    test "when unauthenticated, returns Unauthorized error", %{conn: conn} do
      response =
        conn
        |> get(~p"/api/notifications/counts")
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
    end

    @tag authenticated: :admin
    test "when authenticated as notification receiver with no mentions, after dismiss by type, returns no mentions",
         %{conn: conn} do
      dismiss_response =
        conn
        |> post(~p"/api/notifications/dismiss", %{"type" => "mention"})
        |> json_response(200)

      assert dismiss_response == %{"success" => true}

      response =
        conn
        |> get(~p"/api/notifications/counts", %{})
        |> json_response(200)

      assert response["mention"] == 0
      assert response["message"] == 0
    end

    @tag authenticated: :admin
    test "when authenticated as notification receiver, after dismiss of incorrect type, returns unchanged mentions count",
         %{conn: conn} do
      dismiss_response =
        conn
        |> post(~p"/api/notifications/dismiss", %{"type" => "message"})
        |> json_response(200)

      assert dismiss_response == %{"success" => true}

      response =
        conn
        |> get(~p"/api/notifications/counts", %{})
        |> json_response(200)

      assert response["mention"] == @mentions_count
      assert response["message"] == 0
    end

    @tag authenticated: :admin
    test "when authenticated as notification receiver, after dismiss by mention id, returns updated mentions count",
         %{conn: conn, mentions: mentions} do
      Enum.reduce(mentions, @mentions_count, fn mention, count ->
        dismiss_response =
          conn
          |> post(~p"/api/notifications/dismiss", %{"id" => mention.id})
          |> json_response(200)

        assert dismiss_response == %{"success" => true}

        response =
          conn
          |> get(~p"/api/notifications/counts", %{})
          |> json_response(200)

        assert response["mention"] == count - 1
        assert response["message"] == 0
        count - 1
      end)
    end
  end
end
