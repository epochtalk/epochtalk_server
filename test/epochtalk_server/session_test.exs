defmodule Test.EpochtalkServer.Session do
  @moduledoc """
  This test sets async: false because it uses redis session storage, which will
  run into concurrency issues when run alongside other tests
  """
  use Test.Support.ConnCase, async: false
  import Test.Support.Factory
  @one_day_in_seconds 1 * 24 * 60 * 60
  @almost_one_day_in_seconds @one_day_in_seconds - 100
  @four_weeks_in_seconds 4 * 7 * @one_day_in_seconds
  @almost_four_weeks_in_seconds @four_weeks_in_seconds - 100
  @max_date "9999-12-31 00:00:00.000000"
  alias EpochtalkServer.Session
  alias EpochtalkServer.Models.Profile
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.RoleUser
  alias EpochtalkServer.Cache.Role, as: RoleCache
  alias EpochtalkServer.Models.Ban
  alias EpochtalkServer.Models.BoardModerator

  describe "get_resource/2" do
    test "when session_id is invalid, errors", %{users: %{user: user}} do
      session_id = "bogussessionid"

      assert Session.get_resource(user.id, session_id) ==
               {:error, "No session for user_id #{user.id} with id #{session_id}"}
    end

    @tag :authenticated
    test "when user id is invalid, errors", %{conn: conn} do
      user_id = 0
      # get session_id (jti) from conn
      session_id = conn.private.guardian_default_claims["jti"]

      assert Session.get_resource(user_id, session_id) ==
               {:error, "No session for user_id #{user_id} with id #{session_id}"}
    end

    @tag :authenticated
    test "when authenticated, gets a valid resource", %{conn: conn, authed_user: authed_user} do
      # get session_id (jti) from conn
      session_id = conn.private.guardian_default_claims["jti"]
      {:ok, resource_user} = Session.get_resource(authed_user.id, session_id)
      assert authed_user.id == resource_user.id
    end
  end

  describe "delete/1" do
    @tag :authenticated
    test "deletes authenticated user's session", %{conn: conn, authed_user: authed_user} do
      session_id = conn.private.guardian_default_claims["jti"]
      {:ok, resource} = Session.get_resource(authed_user.id, session_id)
      %{id: session_user_id, username: session_user_username} = resource
      assert session_user_id == authed_user.id
      assert session_user_username == authed_user.username

      # delete user session indirectly via logout route
      #   this is done rather than calling Session.delete
      #   because guardian does not load the resource
      #   when calling Session.delete directly
      unauthed_conn = delete(conn, Routes.user_path(conn, :logout))
      assert Guardian.Plug.authenticated?(unauthed_conn) == false
      unauthed_resource = Session.get_resource(authed_user.id, session_id)

      assert unauthed_resource ==
               {:error, "No session for user_id #{authed_user.id} with id #{session_id}"}
    end
  end

  describe "create/3 session expiration" do
    test "when logging in, deletes an expired user session", %{conn: conn, users: %{user: user}} do
      remember_me = false
      # create session that should be deleted
      {:ok, _authed_user_to_delete, _token, authed_conn_to_delete} =
        Session.create(user, remember_me, conn)

      session_id_to_delete = authed_conn_to_delete.private.guardian_default_claims["jti"]
      # create session that shouldn't be deleted
      {:ok, _authed_user_to_persist, _token, authed_conn_to_persist} =
        Session.create(user, remember_me, conn)

      session_id_to_persist = authed_conn_to_persist.private.guardian_default_claims["jti"]
      # check that all sessions are active
      {:ok, resource_to_delete} = Session.get_resource(user.id, session_id_to_delete)

      %{id: session_user_id_to_delete, username: session_user_username_to_delete} =
        resource_to_delete

      assert session_user_id_to_delete == user.id
      assert session_user_username_to_delete == user.username
      {:ok, resource_to_persist} = Session.get_resource(user.id, session_id_to_persist)

      %{id: session_user_id_to_persist, username: session_user_username_to_persist} =
        resource_to_persist

      assert session_user_id_to_persist == user.id
      assert session_user_username_to_persist == user.username
      # change expiration of session to delete to UTC 0
      expiration_utc = 0

      Redix.command(:redix, [
        "ZADD",
        "user:#{user.id}:sessions",
        expiration_utc,
        session_id_to_delete
      ])

      # create a new session (should delete expired sessions)
      {:ok, _new_authed_user, _token, new_authed_conn} = Session.create(user, remember_me, conn)
      new_session_id = new_authed_conn.private.guardian_default_claims["jti"]
      # check that active sessions are still active
      {:ok, resource_to_persist} = Session.get_resource(user.id, session_id_to_persist)

      %{id: session_user_id_to_persist, username: session_user_username_to_persist} =
        resource_to_persist

      assert session_user_id_to_persist == user.id
      assert session_user_username_to_persist == user.username

      authenticate_persisted_response =
        authed_conn_to_persist
        |> get(Routes.user_path(authed_conn_to_persist, :authenticate))
        |> json_response(200)

      assert authenticate_persisted_response["id"] == user.id
      {:ok, new_resource} = Session.get_resource(user.id, new_session_id)
      %{id: new_session_user_id, username: new_session_user_username} = new_resource
      assert new_session_user_id == user.id
      assert new_session_user_username == user.username

      new_authenticate_response =
        new_authed_conn
        |> get(Routes.user_path(new_authed_conn, :authenticate))
        |> json_response(200)

      assert new_authenticate_response["id"] == user.id
      # check that expired session is not active
      unauthed_resource = Session.get_resource(user.id, session_id_to_delete)

      assert unauthed_resource ==
               {:error, "No session for user_id #{user.id} with id #{session_id_to_delete}"}

      authenticate_deleted_response =
        authed_conn_to_delete
        |> get(Routes.user_path(authed_conn_to_delete, :authenticate))
        |> json_response(401)

      assert authenticate_deleted_response["error"] == "Unauthorized"
      assert authenticate_deleted_response["message"] == "No resource found"
    end
  end

  describe "create/3 expiration/ttl" do
    setup [:flush_redis]

    test "without remember me, creates a user session (< 1 day ttl)", %{
      conn: conn,
      users: %{user: user}
    } do
      remember_me = false
      {:ok, authed_user, _token, _authed_conn} = Session.create(user, remember_me, conn)
      user_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}"])
      roles_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:roles"])
      moderating_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:moderating"])
      baninfo_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:baninfo"])
      sessions_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:sessions"])

      assert user_ttl > @almost_one_day_in_seconds
      assert user_ttl <= @one_day_in_seconds
      assert roles_ttl > @almost_one_day_in_seconds
      assert roles_ttl <= @one_day_in_seconds
      assert moderating_ttl <= @one_day_in_seconds
      assert baninfo_ttl <= @one_day_in_seconds
      assert sessions_ttl > @almost_one_day_in_seconds
      assert sessions_ttl <= @one_day_in_seconds
    end

    test "with remember me, creates a user session (< 4 week ttl)", %{
      conn: conn,
      users: %{user: user}
    } do
      remember_me = true
      {:ok, authed_user, _token, _authed_conn} = Session.create(user, remember_me, conn)
      user_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}"])
      roles_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:roles"])
      moderating_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:moderating"])
      baninfo_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:baninfo"])
      sessions_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:sessions"])

      assert user_ttl > @almost_four_weeks_in_seconds
      assert user_ttl <= @four_weeks_in_seconds
      assert roles_ttl > @almost_four_weeks_in_seconds
      assert roles_ttl <= @four_weeks_in_seconds
      assert moderating_ttl <= @four_weeks_in_seconds
      assert baninfo_ttl <= @four_weeks_in_seconds
      assert sessions_ttl > @almost_four_weeks_in_seconds
      assert sessions_ttl <= @four_weeks_in_seconds
    end

    test "handles updating ttl", %{conn: conn, users: %{user: user}} do
      remember_me_1 = false
      {:ok, authed_user_1, _token, _authed_conn} = Session.create(user, remember_me_1, conn)
      user_ttl_1 = Redix.command!(:redix, ["TTL", "user:#{authed_user_1.id}"])
      roles_ttl_1 = Redix.command!(:redix, ["TTL", "user:#{authed_user_1.id}:roles"])
      moderating_ttl_1 = Redix.command!(:redix, ["TTL", "user:#{authed_user_1.id}:moderating"])
      baninfo_ttl_1 = Redix.command!(:redix, ["TTL", "user:#{authed_user_1.id}:baninfo"])
      sessions_ttl_1 = Redix.command!(:redix, ["TTL", "user:#{authed_user_1.id}:sessions"])

      assert user_ttl_1 > @almost_one_day_in_seconds
      assert user_ttl_1 <= @one_day_in_seconds
      assert roles_ttl_1 > @almost_one_day_in_seconds
      assert roles_ttl_1 <= @one_day_in_seconds
      assert moderating_ttl_1 <= @one_day_in_seconds
      assert baninfo_ttl_1 <= @one_day_in_seconds
      assert sessions_ttl_1 > @almost_one_day_in_seconds
      assert sessions_ttl_1 <= @one_day_in_seconds

      remember_me_2 = true
      {:ok, authed_user_2, _token, _authed_conn} = Session.create(user, remember_me_2, conn)
      user_ttl_2 = Redix.command!(:redix, ["TTL", "user:#{authed_user_2.id}"])
      roles_ttl_2 = Redix.command!(:redix, ["TTL", "user:#{authed_user_2.id}:roles"])
      moderating_ttl_2 = Redix.command!(:redix, ["TTL", "user:#{authed_user_2.id}:moderating"])
      baninfo_ttl_2 = Redix.command!(:redix, ["TTL", "user:#{authed_user_2.id}:baninfo"])
      sessions_ttl_2 = Redix.command!(:redix, ["TTL", "user:#{authed_user_2.id}:sessions"])

      assert user_ttl_2 > @almost_four_weeks_in_seconds
      assert user_ttl_2 <= @four_weeks_in_seconds
      assert roles_ttl_2 > @almost_four_weeks_in_seconds
      assert roles_ttl_2 <= @four_weeks_in_seconds
      assert moderating_ttl_2 <= @four_weeks_in_seconds
      assert baninfo_ttl_2 <= @four_weeks_in_seconds
      assert sessions_ttl_2 > @almost_four_weeks_in_seconds
      assert sessions_ttl_2 <= @four_weeks_in_seconds

      remember_me_3 = false
      {:ok, authed_user_3, _token, _authed_conn} = Session.create(user, remember_me_3, conn)
      user_ttl_3 = Redix.command!(:redix, ["TTL", "user:#{authed_user_3.id}"])
      roles_ttl_3 = Redix.command!(:redix, ["TTL", "user:#{authed_user_3.id}:roles"])
      moderating_ttl_3 = Redix.command!(:redix, ["TTL", "user:#{authed_user_3.id}:moderating"])
      baninfo_ttl_3 = Redix.command!(:redix, ["TTL", "user:#{authed_user_3.id}:baninfo"])
      sessions_ttl_3 = Redix.command!(:redix, ["TTL", "user:#{authed_user_3.id}:sessions"])

      assert user_ttl_3 > @almost_four_weeks_in_seconds
      assert user_ttl_3 <= @four_weeks_in_seconds
      assert roles_ttl_3 > @almost_four_weeks_in_seconds
      assert roles_ttl_3 <= @four_weeks_in_seconds
      assert moderating_ttl_3 <= @four_weeks_in_seconds
      assert baninfo_ttl_3 <= @four_weeks_in_seconds
      assert sessions_ttl_3 > @almost_four_weeks_in_seconds
      assert sessions_ttl_3 <= @four_weeks_in_seconds
    end

    @tag :banned
    test "without remember me, handles baninfo ttl and ban_expiration (< 1 day ttl)", %{
      conn: conn,
      user_attrs: %{banned_user: user_attrs},
      users: %{banned_user: user}
    } do
      pre_ban_baninfo_ttl = Redix.command!(:redix, ["TTL", "user:#{user.id}:baninfo"])

      pre_ban_ban_expiration =
        Redix.command!(:redix, ["HGET", "user:#{user.id}:baninfo", "ban_expiration"])

      post(
        conn,
        Routes.user_path(conn, :login, %{
          username: user_attrs.username,
          password: user_attrs.password
        })
      )

      baninfo_ttl = Redix.command!(:redix, ["TTL", "user:#{user.id}:baninfo"])

      ban_expiration =
        Redix.command!(:redix, ["HGET", "user:#{user.id}:baninfo", "ban_expiration"])

      assert pre_ban_ban_expiration == nil
      assert ban_expiration == @max_date
      assert pre_ban_baninfo_ttl == -2
      assert baninfo_ttl <= @one_day_in_seconds
      assert baninfo_ttl > @almost_one_day_in_seconds
    end

    @tag :banned
    test "with remember me, handles baninfo ttl and ban_expiration (< 4 weeks ttl)", %{
      conn: conn,
      user_attrs: %{banned_user: user_attrs},
      users: %{banned_user: user}
    } do
      pre_ban_baninfo_ttl = Redix.command!(:redix, ["TTL", "user:#{user.id}:baninfo"])

      pre_ban_ban_expiration =
        Redix.command!(:redix, ["HGET", "user:#{user.id}:baninfo", "ban_expiration"])

      post(
        conn,
        Routes.user_path(conn, :login, %{
          username: user_attrs.username,
          password: user_attrs.password,
          rememberMe: true
        })
      )

      baninfo_ttl = Redix.command!(:redix, ["TTL", "user:#{user.id}:baninfo"])

      ban_expiration =
        Redix.command!(:redix, ["HGET", "user:#{user.id}:baninfo", "ban_expiration"])

      assert pre_ban_ban_expiration == nil
      assert ban_expiration == @max_date
      assert pre_ban_baninfo_ttl == -2
      assert baninfo_ttl <= @four_weeks_in_seconds
      assert baninfo_ttl > @almost_four_weeks_in_seconds
    end

    @tag :malicious
    test "without remember me, handles baninfo ttl and malicious score (< 1 day ttl)", %{
      conn: conn,
      users: %{user: user},
      malicious_user_changeset: malicious_user_changeset
    } do
      pre_malicious_baninfo_ttl = Redix.command!(:redix, ["TTL", "user:#{user.id}:baninfo"])

      pre_malicious_malicious_score =
        Redix.command!(:redix, ["HGET", "user:#{user.id}:baninfo", "malicious_score"])

      malicious_user = Map.put(user, :malicious_score, malicious_user_changeset.malicious_score)
      remember_me = false
      {:ok, authed_user, _token, _authed_conn} = Session.create(malicious_user, remember_me, conn)

      malicious_score_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:baninfo"])

      malicious_score =
        Redix.command!(:redix, ["HGET", "user:#{authed_user.id}:baninfo", "malicious_score"])

      assert pre_malicious_malicious_score == nil
      assert malicious_score == "2.0416"
      assert pre_malicious_baninfo_ttl == -2
      assert malicious_score_ttl <= @one_day_in_seconds
      assert malicious_score_ttl > @almost_one_day_in_seconds
    end

    @tag :malicious
    test "with remember me, handles baninfo ttl and malicious score (< 4 weeks ttl)", %{
      conn: conn,
      users: %{user: user},
      malicious_user_changeset: malicious_user_changeset
    } do
      pre_malicious_baninfo_ttl = Redix.command!(:redix, ["TTL", "user:#{user.id}:baninfo"])

      pre_malicious_malicious_score =
        Redix.command!(:redix, ["HGET", "user:#{user.id}:baninfo", "malicious_score"])

      malicious_user = Map.put(user, :malicious_score, malicious_user_changeset.malicious_score)
      remember_me = true
      {:ok, authed_user, _token, _authed_conn} = Session.create(malicious_user, remember_me, conn)

      malicious_score_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:baninfo"])

      malicious_score =
        Redix.command!(:redix, ["HGET", "user:#{authed_user.id}:baninfo", "malicious_score"])

      assert pre_malicious_malicious_score == nil
      assert malicious_score == "2.0416"
      assert pre_malicious_baninfo_ttl == -2
      assert malicious_score_ttl <= @four_weeks_in_seconds
      assert malicious_score_ttl > @almost_four_weeks_in_seconds
    end
  end

  describe "update/1" do
    test "given invalid user id, errors with :user_not_found" do
      assert Session.update(0) == {:error, :user_not_found}
    end

    test "given user id without sessions, errors with :no_sessions", %{
      users: %{no_login_user: user}
    } do
      assert Session.update(user.id) == {:error, :no_sessions}
    end

    @tag :authenticated
    test "given a valid user id, updates avatar", %{conn: conn, authed_user: authed_user} do
      updated_attrs = %{avatar: "image.png"}
      Profile.upsert(authed_user.id, updated_attrs)
      Session.update(authed_user.id)
      # get session_id (jti) from conn
      session_id = conn.private.guardian_default_claims["jti"]
      {:ok, resource_user} = Session.get_resource(authed_user.id, session_id)
      assert resource_user.avatar == updated_attrs.avatar
    end
  end

  describe "update/1 role" do
    @tag :authenticated
    test "given a valid user id, updates role to admin", %{conn: conn, authed_user: authed_user} do
      authed_user_role = List.first(authed_user.roles)
      assert authed_user_role == RoleCache.by_lookup("user")
      RoleUser.set_admin(authed_user.id)
      Session.update(authed_user.id)
      # get session_id (jti) from conn
      session_id = conn.private.guardian_default_claims["jti"]
      {:ok, resource_user} = Session.get_resource(authed_user.id, session_id)
      resource_user_role = List.first(resource_user.roles)
      assert resource_user_role == RoleCache.by_lookup("superAdministrator")
    end

    @tag authenticated: :super_admin
    test "given a valid superAdministrator id, updates role to delete admin + add user", %{
      conn: conn,
      authed_user: authed_user
    } do
      authed_user_role = List.first(authed_user.roles)
      super_administrator_role = RoleCache.by_lookup("superAdministrator")
      assert authed_user_role == super_administrator_role
      RoleUser.delete(super_administrator_role.id, authed_user.id)
      Session.update(authed_user.id)
      # get session_id (jti) from conn
      session_id = conn.private.guardian_default_claims["jti"]
      {:ok, resource_user} = Session.get_resource(authed_user.id, session_id)
      resource_user_role = List.first(resource_user.roles)
      user_role = RoleCache.by_lookup("user")
      assert resource_user_role == user_role
    end
  end

  describe "update/1 baninfo" do
    @tag :authenticated
    test "given a not banned user's id, when user is banned, adds banned role", %{
      conn: conn,
      authed_user: authed_user
    } do
      # get session_id (jti) from conn
      session_id = conn.private.guardian_default_claims["jti"]
      # check that session user does not have banned role
      {:ok, resource_user} = Session.get_resource(authed_user.id, session_id)
      assert Enum.any?(resource_user.roles, &(&1.lookup == "banned")) == false

      # ban user
      Ban.ban(authed_user)

      # check that session user has banned role
      Session.update(authed_user.id)
      {:ok, banned_resource_user} = Session.get_resource(authed_user.id, session_id)
      assert Enum.any?(banned_resource_user.roles, &(&1.lookup == "banned")) == true
      # check ban is active
      assert banned_resource_user.ban_expiration == @max_date
    end

    @tag [authenticated: :banned, banned: true]
    test "given a banned user's id, when user is unbanned, deletes banned role", %{
      conn: conn,
      authed_user: authed_user
    } do
      # get session_id (jti) from conn
      session_id = conn.private.guardian_default_claims["jti"]
      # check that session user has banned role
      {:ok, banned_resource_user} = Session.get_resource(authed_user.id, session_id)
      assert Enum.any?(banned_resource_user.roles, &(&1.lookup == "banned")) == true

      # unban user
      Ban.unban_by_user_id(authed_user.id)

      # check that session user does not have banned role
      Session.update(authed_user.id)
      {:ok, unbanned_resource_user} = Session.get_resource(authed_user.id, session_id)
      assert Enum.any?(unbanned_resource_user.roles, &(&1.lookup == "banned")) == false
      # check ban is expired
      now = NaiveDateTime.utc_now()

      {:ok, ban_expiration} =
        unbanned_resource_user.ban_expiration |> NaiveDateTime.from_iso8601()

      assert NaiveDateTime.compare(ban_expiration, now) == :lt
    end

    @tag :authenticated
    test "given a not malicious user's id, when user is marked malicious, adds malicious score",
         %{
           conn: conn,
           authed_user: authed_user
         } do
      # get session_id (jti) from conn
      session_id = conn.private.guardian_default_claims["jti"]
      # check that session user does not have banned role
      {:ok, resource_user} = Session.get_resource(authed_user.id, session_id)
      assert Enum.any?(resource_user.roles, &(&1.lookup == "banned")) == false
      # check user does not have malicious score or ban expiration
      assert Map.get(resource_user, :malicious_score) == nil
      assert Map.get(resource_user, :ban_expiration) == nil

      # update user malicious
      build(:banned_address, ip: "127.0.0.1", weight: 1.0)
      build(:banned_address, hostname: "localhost", weight: 1.0)
      User.handle_malicious_user(authed_user, conn.remote_ip)

      # check that session user has banned role
      Session.update(authed_user.id)
      {:ok, malicious_resource_user} = Session.get_resource(authed_user.id, session_id)
      assert Enum.any?(malicious_resource_user.roles, &(&1.lookup == "banned")) == true
      # check malicious score and ban are active
      assert malicious_resource_user.malicious_score != nil
      assert malicious_resource_user.malicious_score > 1
      assert malicious_resource_user.ban_expiration == @max_date
    end
  end

  describe "update/1 moderating" do
    @tag :authenticated
    test "when a user is added/removed as moderator, updates moderating", %{
      conn: conn,
      authed_user: authed_user
    } do
      # get session_id (jti) from conn
      session_id = conn.private.guardian_default_claims["jti"]
      # check that session user's moderating list is empty
      {:ok, resource_user} = Session.get_resource(authed_user.id, session_id)
      assert Map.get(resource_user, :moderating) == nil

      # create board and add user as moderator
      board = build(:board)
      BoardModerator.add_moderators_by_username(board.id, [authed_user.username])

      # check session user updates with moderating
      Session.update(authed_user.id)
      {:ok, moderator_resource_user} = Session.get_resource(authed_user.id, session_id)
      # check moderating list contains new board
      assert Map.get(moderator_resource_user, :moderating) == [Integer.to_string(board.id)]

      # remove user as moderator
      BoardModerator.remove_moderators_by_username(board.id, [authed_user.username])

      # check session user updates with moderating
      Session.update(authed_user.id)
      {:ok, moderator_resource_user} = Session.get_resource(authed_user.id, session_id)
      # check moderating list contains new board
      assert Map.get(moderator_resource_user, :moderating) == nil
    end
  end

  defp flush_redis(_) do
    Redix.command!(:redix, ["FLUSHALL"])
    :ok
  end
end
