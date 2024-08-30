defmodule Test.EpochtalkServerWeb.Controllers.Poll do
  use Test.Support.ConnCase, async: false
  # this test is running non-async, it causes deadlocks when run in async

  import Test.Support.Factory
  alias EpochtalkServer.Models.Poll
  alias EpochtalkServerWeb.CustomErrors.InvalidPermission

  setup %{users: %{user: user, admin_user: admin_user, super_admin_user: super_admin_user}} do
    board = insert(:board)
    admin_board = insert(:board, viewable_by: 1)
    # readable by admins but only writeable by super admins
    super_admin_board = insert(:board, viewable_by: 1, postable_by: 0)
    category = insert(:category)

    build(:board_mapping,
      attributes: [
        [category: category, view_order: 0],
        [board: board, category: category, view_order: 1],
        [board: admin_board, category: category, view_order: 2],
        [board: super_admin_board, category: category, view_order: 3]
      ]
    )

    admin_board_thread =
      build(:thread, board: admin_board, user: admin_user, poll: build(:poll_attributes))

    super_admin_board_thread =
      build(:thread,
        board: super_admin_board,
        user: super_admin_user,
        poll: build(:poll_attributes)
      )

    super_admin_board_thread_no_poll =
      build(:thread, board: super_admin_board, user: super_admin_user)

    thread_with_poll = build(:thread, board: board, user: user, poll: build(:poll_attributes))

    thread_with_change_vote_poll =
      build(:thread, board: board, user: user, poll: build(:poll_attributes, change_vote: true))

    thread_no_poll = build(:thread, board: board, user: user)

    admin_thread_no_poll = build(:thread, board: board, user: admin_user)

    admin_thread_with_poll =
      build(:thread, board: board, user: admin_user, poll: build(:poll_attributes))

    super_admin_thread_with_poll =
      build(:thread, board: super_admin_board, user: admin_user, poll: build(:poll_attributes))

    {
      :ok,
      admin_board_thread: admin_board_thread,
      super_admin_board_thread: super_admin_board_thread,
      super_admin_board_thread_no_poll: super_admin_board_thread_no_poll,
      thread_with_poll: thread_with_poll,
      thread_with_change_vote_poll: thread_with_change_vote_poll,
      thread_no_poll: thread_no_poll,
      admin_thread_no_poll: admin_thread_no_poll,
      admin_thread_with_poll: admin_thread_with_poll,
      super_admin_thread_with_poll: super_admin_thread_with_poll
    }
  end

  describe "create/2" do
    test "when unauthenticated, returns Unauthorized error", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls", %{
          "question" => "Is this a test?",
          "answers" => ["Yes", "No"],
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
    test "given nonexistant thread, does not create poll", %{
      conn: conn
    } do
      response =
        conn
        |> post(~p"/api/threads/#{-1}/polls", %{
          "question" => "Is this a test?",
          "answers" => ["Yes", "No"],
          "max_answers" => 2,
          "expiration" => nil,
          "display_mode" => "always",
          "change_vote" => false
        })
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, cannot create poll"
    end

    @tag :authenticated
    test "given thread with existing poll, does not create poll", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls", %{
          "question" => "Is this a test?",
          "answers" => ["Yes", "No"],
          "max_answers" => 2,
          "expiration" => nil,
          "display_mode" => "always",
          "change_vote" => false
        })
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, poll already exists"
    end

    @tag :authenticated
    test "given admin thread and insufficient priority, throws forbidden read error", %{
      conn: conn,
      admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls", %{
          "question" => "Is this a test?",
          "answers" => ["Yes", "No"],
          "max_answers" => 2,
          "expiration" => nil,
          "display_mode" => "always",
          "change_vote" => false
        })
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to read"
    end

    @tag authenticated: :admin
    test "given super admin thread and insufficient priority, throws forbidden write error", %{
      conn: conn,
      super_admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls", %{
          "question" => "Is this a test?",
          "answers" => ["Yes", "No"],
          "max_answers" => 2,
          "expiration" => nil,
          "display_mode" => "always",
          "change_vote" => false
        })
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to write"
    end

    @tag authenticated: :banned
    test "given banned authenticated user, throws InvalidPermission forbidden error", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     post(conn, ~p"/api/threads/#{thread_id}/polls", %{
                       "question" => "Is this a test?",
                       "answers" => ["Yes", "No"],
                       "max_answers" => 2,
                       "expiration" => nil,
                       "display_mode" => "always",
                       "change_vote" => false
                     })
                   end
    end

    @tag :authenticated
    test "given admin thread and insufficient priority, throws forbidden write error", %{
      conn: conn,
      admin_thread_no_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls", %{
          "question" => "Is this a test?",
          "answers" => ["Yes", "No"],
          "max_answers" => 2,
          "expiration" => nil,
          "display_mode" => "always",
          "change_vote" => false
        })
        |> json_response(403)

      assert response["error"] == "Forbidden"

      assert response["message"] ==
               "Unauthorized, you do not have permission to create a poll for another user's thread"
    end

    @tag :authenticated
    test "given thread without an existing poll, does create a poll", %{
      conn: conn,
      thread_no_poll: %{post: %{thread_id: thread_id}}
    } do
      poll = %{
        "question" => "Is this a test?",
        "answers" => ["Yes", "No"],
        "max_answers" => 2,
        "expiration" => nil,
        "display_mode" => "always",
        "change_vote" => false
      }

      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls", poll)
        |> json_response(200)

      assert response["id"] != nil
      assert length(response["answers"]) == length(poll["answers"])
      assert response["change_vote"] == poll["change_vote"]
      assert response["display_mode"] == poll["display_mode"]
      assert response["expiration"] == poll["expiration"]
      assert response["has_voted"] == false
      assert response["locked"] == false
      assert response["max_answers"] == poll["max_answers"]
      assert response["question"] == poll["question"]
      assert response["thread_id"] == thread_id
    end

    @tag authenticated: :super_admin
    test "given super admin thread and sufficient priority, does create a poll", %{
      conn: conn,
      super_admin_board_thread_no_poll: %{post: %{thread_id: thread_id}}
    } do
      poll = %{
        "question" => "Is this a test?",
        "answers" => ["Yes", "No"],
        "max_answers" => 2,
        "expiration" => nil,
        "display_mode" => "always",
        "change_vote" => false
      }

      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls", poll)
        |> json_response(200)

      assert response["id"] != nil
      assert length(response["answers"]) == length(poll["answers"])
      assert response["change_vote"] == poll["change_vote"]
      assert response["display_mode"] == poll["display_mode"]
      assert response["expiration"] == poll["expiration"]
      assert response["has_voted"] == false
      assert response["locked"] == false
      assert response["max_answers"] == poll["max_answers"]
      assert response["question"] == poll["question"]
      assert response["thread_id"] == thread_id
    end
  end

  describe "update/2" do
    test "when unauthenticated, returns Unauthorized error", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> put(~p"/api/threads/#{thread_id}/polls", %{
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
    test "given nonexistant thread, does not update poll", %{
      conn: conn
    } do
      response =
        conn
        |> put(~p"/api/threads/#{-1}/polls", %{
          "max_answers" => 2,
          "expiration" => nil,
          "display_mode" => "always",
          "change_vote" => false
        })
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, cannot edit poll"
    end

    @tag :authenticated
    test "given thread without an existing poll, does not update poll", %{
      conn: conn,
      thread_no_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> put(~p"/api/threads/#{thread_id}/polls", %{
          "max_answers" => 2,
          "expiration" => nil,
          "display_mode" => "always",
          "change_vote" => false
        })
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, poll does not exist"
    end

    @tag :authenticated
    test "given admin thread and insufficient priority, throws forbidden read error", %{
      conn: conn,
      admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> put(~p"/api/threads/#{thread_id}/polls", %{
          "max_answers" => 2,
          "expiration" => nil,
          "display_mode" => "always",
          "change_vote" => false
        })
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to read"
    end

    @tag authenticated: :admin
    test "given super admin thread and insufficient priority, throws forbidden write error", %{
      conn: conn,
      super_admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> put(~p"/api/threads/#{thread_id}/polls", %{
          "max_answers" => 2,
          "expiration" => nil,
          "display_mode" => "always",
          "change_vote" => false
        })
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to write"
    end

    @tag authenticated: :banned
    test "given banned authenticated user, throws InvalidPermission forbidden error", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     put(conn, ~p"/api/threads/#{thread_id}/polls", %{
                       "max_answers" => 2,
                       "expiration" => nil,
                       "display_mode" => "always",
                       "change_vote" => false
                     })
                   end
    end

    @tag :authenticated
    test "given admin thread and insufficient priority, throws forbidden write error", %{
      conn: conn,
      admin_thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> put(~p"/api/threads/#{thread_id}/polls", %{
          "max_answers" => 2,
          "expiration" => nil,
          "display_mode" => "always",
          "change_vote" => false
        })
        |> json_response(403)

      assert response["error"] == "Forbidden"

      assert response["message"] ==
               "Unauthorized, you do not have permission to edit another user's poll"
    end

    @tag :authenticated
    test "given thread with an existing poll, does update poll", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      poll = %{
        "max_answers" => 2,
        "expiration" => nil,
        "display_mode" => "always",
        "change_vote" => false
      }

      response =
        conn
        |> put(~p"/api/threads/#{thread_id}/polls", poll)
        |> json_response(200)

      assert response["id"] != nil
      assert response["change_vote"] == poll["change_vote"]
      assert response["display_mode"] == poll["display_mode"]
      assert response["expiration"] == poll["expiration"]
      assert response["max_answers"] == poll["max_answers"]
    end

    @tag authenticated: :super_admin
    test "given super admin thread and sufficient priority, does update a poll", %{
      conn: conn,
      super_admin_thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      poll = %{
        "question" => "Is this a test?",
        "answers" => ["Yes", "No"],
        "max_answers" => 2,
        "expiration" => nil,
        "display_mode" => "always",
        "change_vote" => false
      }

      response =
        conn
        |> put(~p"/api/threads/#{thread_id}/polls", poll)
        |> json_response(200)

      assert response["id"] != nil
      assert response["change_vote"] == poll["change_vote"]
      assert response["display_mode"] == poll["display_mode"]
      assert response["expiration"] == poll["expiration"]
      assert response["max_answers"] == poll["max_answers"]
    end
  end

  describe "lock/2" do
    test "when unauthenticated, returns Unauthorized error", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/lock", %{"locked" => true})
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
    end

    @tag :authenticated
    test "given nonexistant thread, does not lock poll", %{
      conn: conn
    } do
      response =
        conn
        |> post(~p"/api/threads/#{-1}/polls/lock", %{"locked" => true})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, cannot lock poll"
    end

    @tag :authenticated
    test "given admin thread and insufficient priority, throws forbidden read error", %{
      conn: conn,
      admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/lock", %{"locked" => true})
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to read"
    end

    @tag authenticated: :admin
    test "given super admin thread and insufficient priority, throws forbidden write error", %{
      conn: conn,
      super_admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/lock", %{"locked" => true})
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to write"
    end

    @tag authenticated: :banned
    test "given banned authenticated user, throws InvalidPermission forbidden error", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     post(conn, ~p"/api/threads/#{thread_id}/polls/lock", %{"locked" => true})
                   end
    end

    @tag :authenticated
    test "given admin owned thread and insufficient priority, throws forbidden write error", %{
      conn: conn,
      admin_thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/lock", %{"locked" => true})
        |> json_response(403)

      assert response["error"] == "Forbidden"

      assert response["message"] ==
               "Unauthorized, you do not have permission to modify the lock on another user's poll"
    end

    @tag authenticated: :newbie
    test "given thread and user who does not own the poll, does not lock poll", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/lock", %{"locked" => true})
        |> json_response(403)

      assert response["error"] == "Forbidden"

      assert response["message"] ==
               "Unauthorized, you do not have permission to modify the lock on another user's poll"
    end

    @tag :authenticated
    test "given thread withd no poll and poll owner, does not lock poll", %{
      conn: conn,
      thread_no_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/lock", %{"locked" => true})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, poll does not exist"
    end

    @tag :authenticated
    test "given thread with poll and poll owner, does lock poll", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/lock", %{"locked" => true})
        |> json_response(200)

      assert response["locked"] == true
      assert response["thread_id"] == thread_id
    end
  end

  describe "vote/2" do
    test "when unauthenticated, returns Unauthorized error", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}, poll: %{poll_answers: [one, _]}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/vote", %{"answer_ids" => [one.id]})
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
    end

    @tag :authenticated
    test "given nonexistant thread, does not vote on poll", %{
      conn: conn,
      thread_with_poll: %{poll: %{poll_answers: [one, _]}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{-1}/polls/vote", %{"answer_ids" => [one.id]})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, cannot cast vote"
    end

    @tag :authenticated
    test "given admin thread and insufficient priority, throws forbidden read error", %{
      conn: conn,
      admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/vote", %{"answer_ids" => [1]})
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to read"
    end

    @tag authenticated: :admin
    test "given super admin thread and insufficient priority, throws forbidden write error", %{
      conn: conn,
      super_admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/vote", %{"answer_ids" => [1]})
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to write"
    end

    @tag authenticated: :banned
    test "given banned authenticated user, throws InvalidPermission forbidden error", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     post(conn, ~p"/api/threads/#{thread_id}/polls/vote", %{"answer_ids" => [1]})
                   end
    end

    @tag :authenticated
    test "given valid thread and invalid answer id, does not vote on poll", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/vote", %{"answer_ids" => [-1]})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Answer_id does not exist"
    end

    @tag :authenticated
    test "given valid thread and too many answer ids, does not vote on poll", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}, poll: %{poll_answers: [one, two]}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/vote", %{"answer_ids" => [one.id, two.id]})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, 'answer_ids' length too long, too many answers"
    end

    @tag :authenticated
    test "given valid thread with no poll, does not vote on poll", %{
      conn: conn,
      thread_no_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/vote", %{"answer_ids" => [1, 2]})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, poll does not exist"
    end

    @tag :authenticated
    test "given valid thread with locked poll, does not vote on poll", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}, poll: %{poll_answers: [one, _]}}
    } do
      Poll.set_locked(thread_id, true)

      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/vote", %{"answer_ids" => [one.id]})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, poll is locked"
    end

    @tag :authenticated
    test "given valid thread and voting twice, does not vote on poll twice", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}, poll: %{poll_answers: [one, _]}}
    } do
      conn
      |> post(~p"/api/threads/#{thread_id}/polls/vote", %{"answer_ids" => [one.id]})
      |> json_response(200)

      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/vote", %{"answer_ids" => [one.id]})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, you have already voted on this poll"
    end

    @tag :authenticated
    test "given valid thread and invalid answer ids, does not vote on poll", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/vote", %{})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, 'answer_ids' must be a list"
    end

    @tag :authenticated
    test "given valid thread with expired poll, does not vote on poll", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}, poll: %{poll_answers: [one, _]}}
    } do
      Poll.update(%{
        "thread_id" => thread_id,
        "expiration" => NaiveDateTime.utc_now() |> NaiveDateTime.add(1)
      })

      # wait one second for poll to expire
      :timer.sleep(1000)

      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/vote", %{"answer_ids" => [one.id]})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, poll is not currently running"
    end

    @tag :authenticated
    test "given valid thread with expiring poll, does vote on poll", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}, poll: poll = %{poll_answers: [one, _]}}
    } do
      expiration = NaiveDateTime.utc_now() |> NaiveDateTime.add(10)

      expiration_string =
        NaiveDateTime.to_iso8601(expiration) |> String.split(".") |> List.first()

      Poll.update(%{"thread_id" => thread_id, "expiration" => expiration})

      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/vote", %{"answer_ids" => [one.id]})
        |> json_response(200)

      assert response["id"] == poll.id
      assert length(response["answers"]) == length(poll.poll_answers)
      assert response["change_vote"] == poll.change_vote
      assert response["display_mode"] == Atom.to_string(poll.display_mode)
      assert response["expiration"] == expiration_string
      assert response["has_voted"] == true
      assert response["locked"] == false
      assert response["max_answers"] == poll.max_answers
      assert response["question"] == poll.question
      assert response["thread_id"] == poll.thread_id
    end

    @tag :authenticated
    test "given valid thread and answer ids, does vote on poll", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}, poll: poll}
    } do
      [one, _] = poll.poll_answers

      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/vote", %{"answer_ids" => [one.id]})
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
  end

  describe "delete_vote/2" do
    test "when unauthenticated, returns Unauthorized error", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(~p"/api/threads/#{thread_id}/polls/lock", %{"locked" => true})
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
    end

    @tag :authenticated
    test "given nonexistant thread, does not delete vote from poll", %{
      conn: conn
    } do
      response =
        conn
        |> post(~p"/api/threads/#{-1}/polls/lock", %{"locked" => true})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, cannot lock poll"
    end

    @tag :authenticated
    test "given admin thread and insufficient priority, throws forbidden read error", %{
      conn: conn,
      admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> delete(~p"/api/threads/#{thread_id}/polls/vote")
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to read"
    end

    @tag authenticated: :admin
    test "given super admin thread and insufficient priority, throws forbidden write error", %{
      conn: conn,
      super_admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> delete(~p"/api/threads/#{thread_id}/polls/vote")
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to write"
    end

    @tag authenticated: :banned
    test "given banned authenticated user, throws InvalidPermission forbidden error", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     delete(conn, ~p"/api/threads/#{thread_id}/polls/vote")
                   end
    end

    @tag :authenticated
    test "given valid thread with no poll, does note delete vote", %{
      conn: conn,
      thread_no_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> delete(~p"/api/threads/#{thread_id}/polls/vote")
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, poll does not exist"
    end

    @tag :authenticated
    test "given valid thread with locked poll, does not delete vote", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      Poll.set_locked(thread_id, true)

      response =
        conn
        |> delete(~p"/api/threads/#{thread_id}/polls/vote")
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, poll is locked"
    end

    @tag :authenticated
    test "given valid thread and poll that doesn't allow changing votes, does not delete vote", %{
      conn: conn,
      thread_with_poll: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> delete(~p"/api/threads/#{thread_id}/polls/vote")
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, you can't change your vote on this poll"
    end

    @tag :authenticated
    test "given valid thread with expired poll, does not delete vote", %{
      conn: conn,
      thread_with_change_vote_poll: %{post: %{thread_id: thread_id}}
    } do
      Poll.update(%{
        "thread_id" => thread_id,
        "expiration" => NaiveDateTime.utc_now() |> NaiveDateTime.add(1)
      })

      # wait one second for poll to expire
      :timer.sleep(1000)

      response =
        conn
        |> delete(~p"/api/threads/#{thread_id}/polls/vote")
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, poll is not currently running"
    end

    @tag :authenticated
    test "given valid thread with expiring poll that allows changing votes, does delete vote", %{
      conn: conn,
      thread_with_change_vote_poll: %{post: %{thread_id: thread_id}, poll: poll}
    } do
      expiration = NaiveDateTime.utc_now() |> NaiveDateTime.add(10)

      expiration_string =
        NaiveDateTime.to_iso8601(expiration) |> String.split(".") |> List.first()

      Poll.update(%{"thread_id" => thread_id, "expiration" => expiration})

      response =
        conn
        |> delete(~p"/api/threads/#{thread_id}/polls/vote")
        |> json_response(200)

      assert response["id"] == poll.id
      assert length(response["answers"]) == length(poll.poll_answers)
      assert response["change_vote"] == poll.change_vote
      assert response["display_mode"] == Atom.to_string(poll.display_mode)
      assert response["expiration"] == expiration_string
      assert response["has_voted"] == false
      assert response["locked"] == false
      assert response["max_answers"] == poll.max_answers
      assert response["question"] == poll.question
      assert response["thread_id"] == poll.thread_id
    end

    @tag :authenticated
    test "given valid thread and poll that allows changing votes, does delete vote", %{
      conn: conn,
      thread_with_change_vote_poll: %{post: %{thread_id: thread_id}, poll: poll}
    } do
      response =
        conn
        |> delete(~p"/api/threads/#{thread_id}/polls/vote")
        |> json_response(200)

      assert response["id"] == poll.id
      assert length(response["answers"]) == length(poll.poll_answers)
      assert response["change_vote"] == poll.change_vote
      assert response["display_mode"] == Atom.to_string(poll.display_mode)
      assert response["expiration"] == poll.expiration
      assert response["has_voted"] == false
      assert response["locked"] == false
      assert response["max_answers"] == poll.max_answers
      assert response["question"] == poll.question
      assert response["thread_id"] == poll.thread_id
    end
  end
end
