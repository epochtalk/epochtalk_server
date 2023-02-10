defmodule EpochtalkServerWeb.SessionTest do
  @one_day_in_seconds 1 * 24 * 60 * 60
  @almost_one_day_in_seconds @one_day_in_seconds - 100
  @four_weeks_in_seconds 4 * 7 * @one_day_in_seconds
  @almost_four_weeks_in_seconds @four_weeks_in_seconds - 100
  use EpochtalkServerWeb.ConnCase, async: false
  import Ecto.Changeset
  alias EpochtalkServer.Models.User

  @login_create_attrs %{username: "logintest", email: "logintest@test.com", password: "password"}
  @login_no_remember_me_attrs %{username: "logintest", password: "password"}
  @login_remember_me_attrs %{username: "logintest", password: "password", remember_me: "true"}

  describe "login/2" do
    setup [:create_login_user]

    test "creates a user session without remember me (< 1 day ttl)", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :login, @login_no_remember_me_attrs))
      {:ok, user} = User.by_username(@login_no_remember_me_attrs.username)
      user_ttl = Redix.command!(:redix, ["TTL", "user:#{user.id}"])
      roles_ttl = Redix.command!(:redix, ["TTL", "user:#{user.id}:roles"])
      moderating_ttl = Redix.command!(:redix, ["TTL", "user:#{user.id}:moderating"])
      baninfo_ttl = Redix.command!(:redix, ["TTL", "user:#{user.id}:baninfo"])
      sessions_ttl = Redix.command!(:redix, ["TTL", "user:#{user.id}:sessions"])

      assert user_ttl > @almost_one_day_in_seconds
      assert user_ttl <= @one_day_in_seconds
      assert roles_ttl > @almost_one_day_in_seconds
      assert roles_ttl <= @one_day_in_seconds
      assert moderating_ttl <= @one_day_in_seconds
      assert baninfo_ttl <= @one_day_in_seconds
      assert sessions_ttl > @almost_one_day_in_seconds
      assert sessions_ttl <= @one_day_in_seconds
    end

    test "creates a second user session with remember me (< 4 week ttl)", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :login, @login_remember_me_attrs))
      {:ok, user} = User.by_username(@login_remember_me_attrs.username)
      user_ttl = Redix.command!(:redix, ["TTL", "user:#{user.id}"])
      roles_ttl = Redix.command!(:redix, ["TTL", "user:#{user.id}:roles"])
      moderating_ttl = Redix.command!(:redix, ["TTL", "user:#{user.id}:moderating"])
      baninfo_ttl = Redix.command!(:redix, ["TTL", "user:#{user.id}:baninfo"])
      sessions_ttl = Redix.command!(:redix, ["TTL", "user:#{user.id}:sessions"])

      assert user_ttl > @almost_four_weeks_in_seconds
      assert user_ttl <= @four_weeks_in_seconds
      assert roles_ttl > @almost_four_weeks_in_seconds
      assert roles_ttl <= @four_weeks_in_seconds
      assert moderating_ttl <= @four_weeks_in_seconds
      assert baninfo_ttl <= @four_weeks_in_seconds
      assert sessions_ttl > @almost_four_weeks_in_seconds
      assert sessions_ttl <= @four_weeks_in_seconds
    end
  end

  defp create_login_user(_) do
    {:ok, user} = User.create(@login_create_attrs)
    {:ok, user: user}
  end
end
