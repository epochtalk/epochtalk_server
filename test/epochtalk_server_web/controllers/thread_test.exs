defmodule Test.EpochtalkServerWeb.Controllers.Thread do
  use Test.Support.ConnCase, async: true
  import Test.Support.Factory
  alias EpochtalkServerWeb.CustomErrors.InvalidPermission
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.BoardMapping

  setup %{
    users: %{
      user: user,
      mod_user: mod_user,
      admin_user: admin_user,
      super_admin_user: super_admin_user
    }
  } do
    board = build(:board)
    move_board = build(:board)
    admin_board = build(:board, viewable_by: 1)
    super_admin_board = build(:board, viewable_by: 1, postable_by: 0)
    category = build(:category)

    build(:board_mapping,
      attributes: [
        [category: category, view_order: 0],
        [board: board, category: category, view_order: 1],
        [board: admin_board, category: category, view_order: 2],
        [board: super_admin_board, category: category, view_order: 3],
        [board: move_board, category: category, view_order: 4]
      ]
    )

    factory_threads = build_list(3, :thread, board: board, user: user)
    admin_priority_thread = build(:thread, board: board, user: admin_user)
    admin_board_thread = build(:thread, board: admin_board, user: admin_user)
    super_admin_board_thread = build(:thread, board: super_admin_board, user: super_admin_user)

    # create thread and replies in move_board to compare last post info in tests below
    move_board_thread = build(:thread, board: move_board, user: user)

    # create posts in thread created above, this is to get a specific number of thread replies
    [_, {:ok, move_board_last_post}] =
      build_list(2, :post, user: mod_user, thread: move_board_thread.post.thread)

    num_thread_replies = 3
    thread_post_count = num_thread_replies + 1
    thread = build(:thread, board: board, user: user)

    # create posts in thread created above, this is to get a specific number of thread replies
    [_, _, {:ok, board_last_post}] =
      build_list(num_thread_replies, :post, user: user, thread: thread.post.thread)

    # NOTE: building additional posts or threads within "thread" or "move_board_thread"
    # will break move thread tests which tests last post info
    {
      :ok,
      board: board,
      move_board: move_board,
      board_last_post: board_last_post,
      move_board_last_post: move_board_last_post,
      admin_board: admin_board,
      super_admin_board: super_admin_board,
      factory_threads: factory_threads,
      thread_post_count: thread_post_count,
      thread: thread,
      admin_board_thread: admin_board_thread,
      admin_priority_thread: admin_priority_thread,
      super_admin_board_thread: super_admin_board_thread
    }
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
      factory_threads: factory_threads
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

  describe "lock/2" do
    test "when unauthenticated, returns Unauthorized error", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :lock, thread_id), %{"locked" => true})
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
    end

    @tag authenticated: :admin
    test "given nonexistant thread, does not lock thread", %{
      conn: conn
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :lock, -1), %{"locked" => true})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, cannot lock thread"
    end

    @tag authenticated: :mod
    test "when authenticated with insufficient permissions, throws forbidden read error", %{
      conn: conn,
      admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :lock, thread_id), %{"locked" => true})
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to read"
    end

    @tag authenticated: :admin
    test "when authenticated with insufficient permissions, throws forbidden write error", %{
      conn: conn,
      super_admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :lock, thread_id), %{"locked" => true})
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to write"
    end

    @tag authenticated: :banned
    test "when authenticated with banned user, throws InvalidPermission forbidden error", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}}
    } do
      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     post(conn, Routes.thread_path(conn, :lock, thread_id), %{"locked" => true})
                   end
    end

    @tag authenticated: :global_mod
    test "when authenticated with insufficient priority, throws forbidden error", %{
      conn: conn,
      admin_priority_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :lock, thread_id), %{"locked" => true})
        |> json_response(403)

      assert response["error"] == "Forbidden"

      assert response["message"] ==
               "Unauthorized, you do not have permission to modify the lock on another user's thread"
    end

    @tag :authenticated
    test "given thread and user who does not own the thread, does not lock thread", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}}
    } do
      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     post(conn, Routes.thread_path(conn, :lock, thread_id), %{"locked" => true})
                   end
    end

    @tag authenticated: :global_mod
    test "given thread that authenticated user moderates, locks thread", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :lock, thread_id), %{"locked" => true})
        |> json_response(200)

      assert response["locked"] == true
      assert response["thread_id"] == thread_id
    end

    @tag authenticated: :global_mod
    test "given thread that authenticated user moderates, unlocks thread", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}}
    } do
      conn
      |> post(Routes.thread_path(conn, :lock, thread_id), %{"locked" => true})
      |> json_response(200)

      response =
        conn
        |> post(Routes.thread_path(conn, :lock, thread_id), %{"locked" => false})
        |> json_response(200)

      assert response["locked"] == false
      assert response["thread_id"] == thread_id
    end
  end

  describe "sticky/2" do
    test "when unauthenticated, returns Unauthorized error", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :sticky, thread_id), %{"sticky" => true})
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
    end

    @tag authenticated: :admin
    test "given nonexistant thread, does not sticky thread", %{
      conn: conn
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :sticky, -1), %{"sticky" => true})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, cannot sticky thread"
    end

    @tag authenticated: :mod
    test "when authenticated with insufficient permissions, throws forbidden read error", %{
      conn: conn,
      admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :sticky, thread_id), %{"sticky" => true})
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to read"
    end

    @tag authenticated: :admin
    test "when authenticated with insufficient permissions, throws forbidden write error", %{
      conn: conn,
      super_admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :sticky, thread_id), %{"sticky" => true})
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to write"
    end

    @tag authenticated: :banned
    test "when authenticated with banned user, throws InvalidPermission forbidden error", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}}
    } do
      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     post(conn, Routes.thread_path(conn, :sticky, thread_id), %{"sticky" => true})
                   end
    end

    @tag authenticated: :global_mod
    test "when authenticated with insufficient priority, throws forbidden error", %{
      conn: conn,
      admin_priority_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :sticky, thread_id), %{"sticky" => true})
        |> json_response(403)

      assert response["error"] == "Forbidden"

      assert response["message"] ==
               "Unauthorized, you do not have permission to modify another user's thread"
    end

    @tag :authenticated
    test "given thread and user who does not own the thread, does not sticky thread", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}}
    } do
      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     post(conn, Routes.thread_path(conn, :sticky, thread_id), %{"sticky" => true})
                   end
    end

    @tag authenticated: :global_mod
    test "given thread that authenticated user moderates, stickies thread", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :sticky, thread_id), %{"sticky" => true})
        |> json_response(200)

      assert response["sticky"] == true
      assert response["thread_id"] == thread_id
    end

    @tag authenticated: :global_mod
    test "given thread that authenticated user moderates, unstickies thread", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}}
    } do
      conn
      |> post(Routes.thread_path(conn, :sticky, thread_id), %{"sticky" => true})
      |> json_response(200)

      response =
        conn
        |> post(Routes.thread_path(conn, :sticky, thread_id), %{"sticky" => false})
        |> json_response(200)

      assert response["sticky"] == false
      assert response["thread_id"] == thread_id
    end
  end

  describe "purge/2" do
    test "when unauthenticated, returns Unauthorized error", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> delete(Routes.thread_path(conn, :purge, thread_id), %{})
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
    end

    @tag authenticated: :admin
    test "given nonexistant thread, does not purge thread", %{
      conn: conn
    } do
      response =
        conn
        |> delete(Routes.thread_path(conn, :purge, -1), %{})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, cannot purge thread"
    end

    @tag authenticated: :mod
    test "when authenticated with insufficient permissions, throws forbidden read error", %{
      conn: conn,
      admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> delete(Routes.thread_path(conn, :purge, thread_id), %{})
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to read"
    end

    @tag authenticated: :admin
    test "when authenticated with insufficient permissions, throws forbidden write error", %{
      conn: conn,
      super_admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> delete(Routes.thread_path(conn, :purge, thread_id), %{})
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to write"
    end

    @tag authenticated: :banned
    test "when authenticated with banned user, throws InvalidPermission forbidden error", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}}
    } do
      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     delete(conn, Routes.thread_path(conn, :purge, thread_id), %{})
                   end
    end

    @tag authenticated: :global_mod
    test "when authenticated with insufficient priority, throws forbidden error", %{
      conn: conn,
      admin_priority_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> delete(Routes.thread_path(conn, :purge, thread_id), %{})
        |> json_response(403)

      assert response["error"] == "Forbidden"

      assert response["message"] ==
               "Unauthorized, you do not have permission to modify another user's thread"
    end

    @tag :authenticated
    test "given thread and user who does not own the thread, does not purge thread", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}}
    } do
      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     delete(conn, Routes.thread_path(conn, :purge, thread_id), %{})
                   end
    end

    @tag authenticated: :global_mod
    test "given thread that authenticated user moderates, purges thread", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}},
      users: %{user: %{id: user_id}}
    } do
      response =
        conn
        |> delete(Routes.thread_path(conn, :purge, thread_id), %{})
        |> json_response(200)

      assert String.starts_with?(response["board_name"], "Board")
      assert String.starts_with?(response["title"], "Thread title")
      assert response["poster_ids"] == [user_id]
      assert response["user_id"] == user_id
    end

    @tag authenticated: :global_mod
    test "after purging thread, decreases thread posters' post count", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}},
      users: %{user: %{id: user_id}},
      thread_post_count: thread_post_count
    } do
      {:ok, user} = User.by_id(user_id)
      old_post_count = user.profile.post_count

      conn
      |> delete(Routes.thread_path(conn, :purge, thread_id), %{})
      |> json_response(200)

      {:ok, updated_user} = User.by_id(user_id)
      new_post_count = updated_user.profile.post_count

      # we use thread_post_count because all replies to thread are by the
      # same user
      assert new_post_count == old_post_count - thread_post_count
    end
  end

  describe "watch/2" do
    test "when unauthenticated, returns Unauthorized error", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :watch, thread_id), %{})
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
    end

    @tag authenticated: :admin
    test "given nonexistant thread, does not watch thread", %{
      conn: conn
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :watch, -1), %{})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, cannot watch thread"
    end

    @tag authenticated: :mod
    test "when authenticated with insufficient permissions, throws forbidden read error", %{
      conn: conn,
      admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :watch, thread_id), %{})
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to read"
    end

    @tag authenticated: :global_mod
    test "when authenticated with insufficient permissions, throws forbidden error", %{
      conn: conn,
      super_admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :watch, thread_id), %{})
        |> json_response(403)

      assert response["error"] == "Forbidden"

      assert response["message"] ==
               "Unauthorized, you do not have permission to read"
    end

    @tag authenticated: :global_mod
    test "given a valid thread, watches", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}},
      users: %{global_mod_user: %{id: user_id}}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :watch, thread_id), %{})
        |> json_response(200)

      assert response["thread_id"] == thread_id
      assert response["user_id"] == user_id
    end
  end

  describe "unwatch/2" do
    test "when unauthenticated, returns Unauthorized error", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> delete(Routes.thread_path(conn, :unwatch, thread_id), %{})
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
    end

    @tag authenticated: :admin
    test "given nonexistant thread, does not unwatch thread", %{
      conn: conn
    } do
      response =
        conn
        |> delete(Routes.thread_path(conn, :unwatch, -1), %{})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, cannot unwatch thread"
    end

    @tag authenticated: :mod
    test "when authenticated with insufficient permissions, throws forbidden read error", %{
      conn: conn,
      admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> delete(Routes.thread_path(conn, :unwatch, thread_id), %{})
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to read"
    end

    @tag authenticated: :global_mod
    test "when authenticated with insufficient permissions, throws forbidden error", %{
      conn: conn,
      super_admin_board_thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> delete(Routes.thread_path(conn, :unwatch, thread_id), %{})
        |> json_response(403)

      assert response["error"] == "Forbidden"

      assert response["message"] ==
               "Unauthorized, you do not have permission to read"
    end

    @tag authenticated: :global_mod
    test "given a valid thread that is not watched, does not unwatch thread", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}}
    } do
      response =
        conn
        |> delete(Routes.thread_path(conn, :unwatch, thread_id), %{})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, cannot unwatch thread"
    end

    @tag authenticated: :global_mod
    test "given a valid thread, unwatches", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}},
      users: %{global_mod_user: %{id: user_id}}
    } do
      conn
      |> post(Routes.thread_path(conn, :watch, thread_id), %{})
      |> json_response(200)

      response =
        conn
        |> delete(Routes.thread_path(conn, :unwatch, thread_id), %{})
        |> json_response(200)

      assert response["thread_id"] == thread_id
      assert response["user_id"] == user_id
    end
  end

  describe "move/2" do
    test "when unauthenticated, returns Unauthorized error", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}},
      move_board: %{id: board_id}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :move, thread_id), %{new_board_id: board_id})
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
    end

    @tag authenticated: :admin
    test "given nonexistant thread, does not move thread", %{
      conn: conn,
      move_board: %{id: board_id}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :move, -1), %{new_board_id: board_id})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Error, cannot move thread"
    end

    @tag authenticated: :mod
    test "when authenticated with insufficient priority, given admin thread, throws forbidden read error",
         %{
           conn: conn,
           admin_board_thread: %{post: %{thread_id: thread_id}},
           move_board: %{id: board_id}
         } do
      response =
        conn
        |> post(Routes.thread_path(conn, :move, thread_id), %{new_board_id: board_id})
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to read"
    end

    @tag authenticated: :admin
    test "when authenticated with insufficient priority, given super admin thread, throws forbidden write error",
         %{
           conn: conn,
           super_admin_board_thread: %{post: %{thread_id: thread_id}},
           move_board: %{id: board_id}
         } do
      response =
        conn
        |> post(Routes.thread_path(conn, :move, thread_id), %{new_board_id: board_id})
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "Unauthorized, you do not have permission to write"
    end

    @tag authenticated: :banned
    test "when authenticated with banned user, throws InvalidPermission forbidden error", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}},
      move_board: %{id: board_id}
    } do
      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     post(conn, Routes.thread_path(conn, :move, thread_id), %{
                       new_board_id: board_id
                     })
                   end
    end

    @tag authenticated: :mod
    test "when authenticated with insufficient priority, given admin created thread, throws forbidden error",
         %{
           conn: conn,
           admin_priority_thread: %{post: %{thread_id: thread_id}},
           move_board: %{id: board_id}
         } do
      response =
        conn
        |> post(Routes.thread_path(conn, :move, thread_id), %{new_board_id: board_id})
        |> json_response(403)

      assert response["error"] == "Forbidden"

      assert response["message"] ==
               "Unauthorized, you do not have permission to move another user's thread"
    end

    @tag :authenticated
    test "when authenticated, with insufficient permissions, does not move thread", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}},
      move_board: %{id: board_id}
    } do
      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     post(conn, Routes.thread_path(conn, :move, thread_id), %{
                       new_board_id: board_id
                     })
                   end
    end

    @tag authenticated: :global_mod
    test "when authenticated, with valid permissions, moves thread", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}},
      board: %{id: old_board_id, name: old_board_name},
      move_board: %{id: new_board_id}
    } do
      response =
        conn
        |> post(Routes.thread_path(conn, :move, thread_id), %{new_board_id: new_board_id})
        |> json_response(200)

      assert response["old_board_id"] == old_board_id
      assert response["old_board_name"] == old_board_name
    end

    @tag authenticated: :global_mod
    test "after moving thread, decreases old board's post count and thread count", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}},
      board: %{id: old_board_id},
      move_board: %{id: new_board_id},
      thread_post_count: thread_post_count
    } do
      {:ok, old_board} = Board.find_by_id(old_board_id)
      old_post_count = old_board.post_count
      old_thread_count = old_board.thread_count

      conn
      |> post(Routes.thread_path(conn, :move, thread_id), %{new_board_id: new_board_id})
      |> json_response(200)

      {:ok, old_board} = Board.find_by_id(old_board_id)
      new_post_count = old_board.post_count
      new_thread_count = old_board.thread_count

      # assuming one post in thread
      assert new_post_count == old_post_count - thread_post_count
      assert new_thread_count == old_thread_count - 1
    end

    @tag authenticated: :global_mod
    test "after moving thread, increases new board's post count and thread count", %{
      conn: conn,
      thread: %{post: %{thread_id: thread_id}},
      move_board: %{id: new_board_id},
      thread_post_count: thread_post_count
    } do
      {:ok, new_board} = Board.find_by_id(new_board_id)
      old_post_count = new_board.post_count
      old_thread_count = new_board.thread_count

      conn
      |> post(Routes.thread_path(conn, :move, thread_id), %{new_board_id: new_board_id})
      |> json_response(200)

      {:ok, new_board} = Board.find_by_id(new_board_id)
      new_post_count = new_board.post_count
      new_thread_count = new_board.thread_count

      # assuming one post in thread
      assert new_post_count == old_post_count + thread_post_count
      assert new_thread_count == old_thread_count + 1
    end

    @tag authenticated: :global_mod
    test "after moving thread, updates last post info of each board", %{
      conn: conn,
      board: %{id: old_board_id},
      move_board: %{id: new_board_id},
      board_last_post: old_board_last_post,
      admin_priority_thread: old_board_second_to_last_thread,
      move_board_last_post: new_board_last_post
    } do
      all_boards = BoardMapping.all()
      [old_board_before_move] = Enum.filter(all_boards, fn bm -> bm.board_id == old_board_id end)
      [new_board_before_move] = Enum.filter(all_boards, fn bm -> bm.board_id == new_board_id end)

      old_board_last_thread = Thread.find(old_board_last_post.thread_id)
      new_board_last_thread = Thread.find(new_board_last_post.thread_id)

      old_board_last_post = old_board_last_post |> Repo.preload(:user)
      new_board_last_post = new_board_last_post |> Repo.preload(:user)

      # Check each board's last post info before moving
      assert old_board_before_move.stats.last_thread_id == old_board_last_post.thread_id
      assert old_board_before_move.stats.last_post_created_at == old_board_last_post.created_at
      assert old_board_before_move.stats.last_post_position == old_board_last_post.position
      assert old_board_before_move.stats.last_post_username == old_board_last_post.user.username
      assert old_board_before_move.stats.last_thread_title == old_board_last_thread.title
      assert old_board_before_move.stats.last_thread_id == old_board_last_thread.id

      assert new_board_before_move.stats.last_thread_id == new_board_last_post.thread_id
      assert new_board_before_move.stats.last_post_created_at == new_board_last_post.created_at
      assert new_board_before_move.stats.last_post_position == new_board_last_post.position
      assert new_board_before_move.stats.last_post_username == new_board_last_post.user.username
      assert new_board_before_move.stats.last_thread_title == new_board_last_thread.title
      assert new_board_before_move.stats.last_thread_id == new_board_last_thread.id

      thread_id = old_board_before_move.stats.last_thread_id

      conn
      |> post(Routes.thread_path(conn, :move, thread_id), %{new_board_id: new_board_id})
      |> json_response(200)

      all_boards = BoardMapping.all()
      [old_board_after_move] = Enum.filter(all_boards, fn bm -> bm.board_id == old_board_id end)
      [new_board_after_move] = Enum.filter(all_boards, fn bm -> bm.board_id == new_board_id end)

      old_board_last_thread = Thread.find(old_board_last_post.thread_id)
      old_board_new_last_thread = Thread.find(old_board_second_to_last_thread.post.thread_id)
      old_board_new_last_post = old_board_second_to_last_thread.post |> Repo.preload(:user)

      # Check old board's last post info after moving, should not be the same
      assert old_board_after_move.stats.last_thread_id != old_board_last_post.thread_id
      assert old_board_after_move.stats.last_post_created_at != old_board_last_post.created_at
      assert old_board_after_move.stats.last_post_position != old_board_last_post.position
      assert old_board_after_move.stats.last_post_username != old_board_last_post.user.username
      assert old_board_after_move.stats.last_thread_title != old_board_last_thread.title
      assert old_board_after_move.stats.last_thread_id != old_board_last_thread.id

      # Check old board's last post is now the previous second to last post that was in the board
      assert old_board_after_move.stats.last_thread_id == old_board_new_last_post.thread_id
      assert old_board_after_move.stats.last_post_created_at == old_board_new_last_post.created_at
      assert old_board_after_move.stats.last_post_position == old_board_new_last_post.position

      assert old_board_after_move.stats.last_post_username ==
               old_board_new_last_post.user.username

      assert old_board_after_move.stats.last_thread_title == old_board_new_last_thread.title
      assert old_board_after_move.stats.last_thread_id == old_board_new_last_thread.id

      # Check new board's last post info after moving, should be the old boards last post
      assert new_board_after_move.stats.last_thread_id == old_board_last_post.thread_id
      assert new_board_after_move.stats.last_post_created_at == old_board_last_post.created_at
      assert new_board_after_move.stats.last_post_position == old_board_last_post.position
      assert new_board_after_move.stats.last_post_username == old_board_last_post.user.username
      assert new_board_after_move.stats.last_thread_title == old_board_last_thread.title
      assert new_board_after_move.stats.last_thread_id == old_board_last_thread.id
    end
  end
end
