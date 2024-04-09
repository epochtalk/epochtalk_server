defmodule Test.EpochtalkServerWeb.Controllers.Thread do
  use Test.Support.ConnCase, async: true
  import Test.Support.Factory
  alias EpochtalkServer.Models.Poll

  setup %{users: %{user: user, admin_user: admin_user, super_admin_user: super_admin_user}} do
    board = insert(:board)
    admin_board = insert(:board, viewable_by: 1)
    super_admin_board = insert(:board, viewable_by: 0)
    category = insert(:category)

    build(:board_mapping,
      attributes: [
        [category: category, view_order: 0],
        [board: board, category: category, view_order: 1],
        [board: admin_board, category: category, view_order: 2],
        [board: super_admin_board, category: category, view_order: 3]
      ]
    )

    threads = build_list(3, :thread, board: board, user: user)
    admin_threads = build_list(3, :thread, board: admin_board, user: admin_user)
    super_admin_threads = build_list(3, :thread, board: super_admin_board, user: super_admin_user)

    thread_with_poll =
      build(:thread,
        board: board,
        user: user,
        poll: build(:poll_attributes)
      )

    thread_no_poll =
      build(:thread,
        board: board,
        user: user
      )

    {
      :ok,
      board: board,
      admin_board: admin_board,
      super_admin_board: super_admin_board,
      threads: threads,
      admin_threads: admin_threads,
      super_admin_threads: super_admin_threads,
      thread_with_poll: thread_with_poll,
      thread_no_poll: thread_no_poll
    }
  end

  describe "update_poll/2" do
    test "when unauthenticated, returns Unauthorized error", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> put(Routes.thread_path(conn, :update_poll, thread_id), %{
          "max_answers" => 2,
          "expiration" => nil,
          "display_mode" => "always",
          "change_vote" => false
        })
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
    end

    @tag :authenticated
    test "given an id for nonexistant thread, does not lock poll", %{
      conn: conn
    } do
      response =
        conn
        |> put(Routes.thread_path(conn, :update_poll, -1), %{
          "max_answers" => 2,
          "expiration" => nil,
          "display_mode" => "always",
          "change_vote" => false
        })
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, cannot edit thread poll"
    end
  end

  describe "lock_poll/2" do
    test "when unauthenticated, returns Unauthorized error", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :lock_poll, thread_id), %{"locked" => true})
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
    end

    @tag :authenticated
    test "given an id for nonexistant thread, does not lock poll", %{
      conn: conn
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :lock_poll, -1), %{"locked" => true})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, cannot lock thread poll"
    end
  end

  describe "vote/2" do
    test "when unauthenticated, returns Unauthorized error", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}, poll: %{poll_answers: [one, _]}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :vote, thread_id), %{"answer_ids" => [one.id]})
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
    end

    @tag :authenticated
    test "given an id for nonexistant thread, does not vote on poll", %{
      conn: conn,
      thread_with_poll: %{poll: %{poll_answers: [one, _]}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :vote, -1), %{"answer_ids" => [one.id]})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, cannot cast vote"
    end

    @tag :authenticated
    test "given valid thread and answer ids, does vote on poll", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}, poll: poll}
    } do
      [one, _] = poll.poll_answers

      response =
        conn
        |> post(Routes.thread_path(conn, :vote, thread_id), %{"answer_ids" => [one.id]})
        |> json_response(200)

      assert response["id"] == poll.id
      assert length(response["answers"]) == length(poll.poll_answers)
      assert response["change_vote"] == poll.change_vote
      assert response["display_mode"] == Atom.to_string(poll.display_mode)
      assert response["expiration"] == poll.expiration
      assert response["has_voted"] == true
      assert response["locked"] == false
      assert response["max_answers"] == poll.max_answers
      assert response["question"] == poll.question
      assert response["thread_id"] == poll.thread_id
    end

    @tag :authenticated
    test "given valid thread id and invalid answer id, does not vote on poll", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :vote, thread_id), %{"answer_ids" => [-1]})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Answer_id does not exist"
    end

    @tag :authenticated
    test "given valid thread id and too many answer ids, does not vote on poll", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}, poll: %{poll_answers: [one, two]}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :vote, thread_id), %{"answer_ids" => [one.id, two.id]})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, 'answer_ids' length too long, too many answers"
    end

    @tag :authenticated
    test "given valid thread id with no poll, does not vote on poll", %{
      conn: conn,
      thread_no_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :vote, thread_id), %{"answer_ids" => [1, 2]})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, poll does not exist"
    end

    @tag :authenticated
    test "given valid thread id with locked poll, does not vote on poll", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}, poll: %{poll_answers: [one, _]}}
    } do
      Poll.set_locked(thread_id, true)

      response =
        conn
        |> post(Routes.thread_path(conn, :vote, thread_id), %{"answer_ids" => [one.id]})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, poll is locked"
    end

    @tag :authenticated
    test "given valid thread id and voting twice, does not vote on poll twice", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}, poll: %{poll_answers: [one, _]}}
    } do
      conn
      |> post(Routes.thread_path(conn, :vote, thread_id), %{"answer_ids" => [one.id]})
      |> json_response(200)

      response =
        conn
        |> post(Routes.thread_path(conn, :vote, thread_id), %{"answer_ids" => [one.id]})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, you have already voted on this poll"
    end

    @tag :authenticated
    test "given valid thread id and invalid answer ids, does not vote on poll", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :vote, thread_id), %{})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, 'answer_ids' must be a list"
    end
  end

  describe "by_board/2" do
    test "given an id for nonexistant board, does not get threads", %{conn: conn} do
      response =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: -1})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Read error, board does not exist"
    end

    test "given an id for existing board, gets threads", %{
      conn: conn,
      board: board,
      threads: factory_threads
    } do
      response =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: board.id})
        |> json_response(200)

      assert Map.has_key?(response, "normal") == true
      assert Map.has_key?(response, "sticky") == true

      # check thread keys
      normal_threads = response["normal"]
      first_thread = normal_threads |> List.first()
      assert Map.has_key?(first_thread, "created_at") == true
      assert Map.has_key?(first_thread, "last_post_avatar") == true
      assert Map.has_key?(first_thread, "last_post_created_at") == true
      assert Map.has_key?(first_thread, "last_post_id") == true
      assert Map.has_key?(first_thread, "last_post_position") == true
      assert Map.has_key?(first_thread, "last_post_username") == true
      assert Map.has_key?(first_thread, "locked") == true
      assert Map.has_key?(first_thread, "moderated") == true
      assert Map.has_key?(first_thread, "poll") == true
      assert Map.has_key?(first_thread, "post_count") == true
      assert Map.has_key?(first_thread, "slug") == true
      assert Map.has_key?(first_thread, "sticky") == true
      assert Map.has_key?(first_thread, "title") == true
      assert Map.has_key?(first_thread, "updated_at") == true
      assert Map.has_key?(first_thread, "user") == true
      assert Map.has_key?(first_thread, "view_count") == true

      # compare to factory results
      factory_threads = factory_threads |> Enum.sort(&(&1.post.thread.id < &2.post.thread.id))
      normal_threads = normal_threads |> Enum.sort(&(Map.get(&1, "id") < Map.get(&2, "id")))

      Enum.zip(normal_threads, factory_threads)
      |> Enum.each(fn {normal_thread, factory_thread} ->
        factory_thread_attributes = factory_thread.attributes
        assert Map.get(normal_thread, "id") == factory_thread.post.thread.id
        assert Map.get(normal_thread, "locked") == Map.get(factory_thread_attributes, "locked")

        assert Map.get(normal_thread, "moderated") ==
                 Map.get(normal_thread, "moderated")

        assert Map.get(normal_thread, "slug") == Map.get(factory_thread_attributes, "slug")
        assert Map.get(normal_thread, "sticky") == Map.get(factory_thread_attributes, "sticky")
        assert Map.get(normal_thread, "title") == Map.get(factory_thread_attributes, "title")
      end)
    end

    test "given an id for board above unauthenticated user priority, does not get threads", %{
      conn: conn,
      admin_board: admin_board,
      super_admin_board: super_admin_board
    } do
      admin_board_response =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: admin_board.id})
        |> json_response(403)

      super_admin_board_response =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: super_admin_board.id})
        |> json_response(403)

      assert admin_board_response["error"] == "Forbidden"
      assert admin_board_response["message"] == "Unauthorized, you do not have permission"
      assert super_admin_board_response["error"] == "Forbidden"
      assert super_admin_board_response["message"] == "Unauthorized, you do not have permission"
    end

    @tag :authenticated
    test "given an id for board above authenticated user priority, does not get threads", %{
      conn: conn,
      admin_board: admin_board,
      super_admin_board: super_admin_board
    } do
      admin_board_response =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: admin_board.id})
        |> json_response(403)

      super_admin_board_response =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: super_admin_board.id})
        |> json_response(403)

      assert admin_board_response["error"] == "Forbidden"
      assert admin_board_response["message"] == "Unauthorized, you do not have permission"
      assert super_admin_board_response["error"] == "Forbidden"
      assert super_admin_board_response["message"] == "Unauthorized, you do not have permission"
    end

    @tag authenticated: :admin
    test "given an id for board at authenticated user priority (admin), gets threads", %{
      conn: conn,
      admin_board: admin_board
    } do
      response =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: admin_board.id})
        |> json_response(200)

      assert Map.has_key?(response, "normal") == true
      assert Map.has_key?(response, "sticky") == true
    end

    @tag authenticated: :super_admin
    test "given an id for board within authenticated user priority (super_admin), gets threads",
         %{
           conn: conn,
           admin_board: admin_board
         } do
      response =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: admin_board.id})
        |> json_response(200)

      assert Map.has_key?(response, "normal") == true
      assert Map.has_key?(response, "sticky") == true
    end

    @tag authenticated: :super_admin
    test "given an id for board at authenticated user priority (super_admin), gets threads", %{
      conn: conn,
      super_admin_board: super_admin_board
    } do
      response =
        conn
        |> get(Routes.thread_path(conn, :by_board), %{board_id: super_admin_board.id})
        |> json_response(200)

      assert Map.has_key?(response, "normal") == true
      assert Map.has_key?(response, "sticky") == true
    end
  end
end
