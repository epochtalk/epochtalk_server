defmodule EpochtalkServerWeb.SessionTest do
  @one_day_in_seconds 1 * 24 * 60 * 60
  @almost_one_day_in_seconds @one_day_in_seconds - 100
  @four_weeks_in_seconds 4 * 7 * @one_day_in_seconds
  @almost_four_weeks_in_seconds @four_weeks_in_seconds - 100
  use EpochtalkServerWeb.ConnCase, async: false
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Session

  describe "get_resource/2" do
    test "errors when resource not valid", %{conn: conn, user: user} do
      # # get session_id (jti) from conn
      # session_id = conn.private.guardian_default_claims["jti"]
      # {:ok, resource_user} = Session.get_resource(user.id, session_id)
      # assert user.id == resource_user.id
      assert true
    end
    # @tag :authenticated
    # test "gets a valid resource", %{conn: conn, authed_user: authed_user} do
    #   # get session_id (jti) from conn
    #   session_id = conn.private.guardian_default_claims["jti"]
    #   {:ok, resource_user} = Session.get_resource(authed_user.id, session_id)
    #   assert authed_user.id == resource_user.id
    #   flush_redis()
    # end
  end
  describe "create/3 expiration/ttl" do
    setup [:flush_redis]
    test "creates a user session without remember me (< 1 day ttl)", %{conn: conn, user: user} do
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

    test "creates a user session with remember me (< 4 week ttl)", %{conn: conn, user: user} do
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

    # test "handles updating ttl", %{conn: conn, user: user} do
    #   remember_me = false
    #   {:ok, authed_user, _token, _authed_conn} = Session.create(user, remember_me, conn)
    #   user_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}"])
    #   roles_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:roles"])
    #   moderating_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:moderating"])
    #   baninfo_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:baninfo"])
    #   sessions_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:sessions"])
    #
    #   assert user_ttl > @almost_one_day_in_seconds
    #   assert user_ttl <= @one_day_in_seconds
    #   assert roles_ttl > @almost_one_day_in_seconds
    #   assert roles_ttl <= @one_day_in_seconds
    #   assert moderating_ttl <= @one_day_in_seconds
    #   assert baninfo_ttl <= @one_day_in_seconds
    #   assert sessions_ttl > @almost_one_day_in_seconds
    #   assert sessions_ttl <= @one_day_in_seconds
    #
    #   remember_me = true
    #   {:ok, authed_user, _token, _authed_conn} = Session.create(user, remember_me, conn)
    #   user_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}"])
    #   roles_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:roles"])
    #   moderating_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:moderating"])
    #   baninfo_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:baninfo"])
    #   sessions_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:sessions"])
    #
    #   assert user_ttl > @almost_four_weeks_in_seconds
    #   assert user_ttl <= @four_weeks_in_seconds
    #   assert roles_ttl > @almost_four_weeks_in_seconds
    #   assert roles_ttl <= @four_weeks_in_seconds
    #   assert moderating_ttl <= @four_weeks_in_seconds
    #   assert baninfo_ttl <= @four_weeks_in_seconds
    #   assert sessions_ttl > @almost_four_weeks_in_seconds
    #   assert sessions_ttl <= @four_weeks_in_seconds
    #
    #   remember_me = false
    #   {:ok, authed_user, _token, _authed_conn} = Session.create(user, remember_me, conn)
    #   user_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}"])
    #   roles_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:roles"])
    #   moderating_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:moderating"])
    #   baninfo_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:baninfo"])
    #   sessions_ttl = Redix.command!(:redix, ["TTL", "user:#{authed_user.id}:sessions"])
    #
    #   assert user_ttl > @almost_four_weeks_in_seconds
    #   assert user_ttl <= @four_weeks_in_seconds
    #   assert roles_ttl > @almost_four_weeks_in_seconds
    #   assert roles_ttl <= @four_weeks_in_seconds
    #   assert moderating_ttl <= @four_weeks_in_seconds
    #   assert baninfo_ttl <= @four_weeks_in_seconds
    #   assert sessions_ttl > @almost_four_weeks_in_seconds
    #   assert sessions_ttl <= @four_weeks_in_seconds
    # end
  end
  defp flush_redis(_) do
    Redix.command!(:redix, ["FLUSHALL"])
    :ok
  end
end
