defmodule EpochtalkServerWeb.UserControllerTest do
  use EpochtalkServerWeb.ConnCase, async: false
  import Ecto.Changeset
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Ban
  alias EpochtalkServer.Repo

  describe "username/2" do
    test "found => true if username is taken", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_path(conn, :username, user.username))
      assert %{"found" => true} = json_response(conn, 200)
    end

    test "found => false if username is not found in the system", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :username, "false_username"))
      assert %{"found" => false} = json_response(conn, 200)
    end
  end

  describe "email/2" do
    test "found => true if email is taken", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_path(conn, :email, user.email))
      assert %{"found" => true} = json_response(conn, 200)
    end

    test "found => false if email is not found in the system", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :email, "false@test.com"))
      assert %{"found" => false} = json_response(conn, 200)
    end
  end

  describe "ban/1" do
    test "user is banned", %{user: user} do
      {:ok, user} = Ban.ban(user)
      assert user.id == user.ban_info.user_id
    end
  end

  describe "unban/1" do
    setup [:ban_user]

    test "user is unbanned", %{banned_user: banned_user} do
      {:ok, banned_user} = Ban.unban(banned_user)
      assert nil == banned_user.ban_info
    end
  end

  describe "handle_malicious_user/2" do
    test "user is banned if malicious", %{conn: conn, user: user} do
      {:ok, user} = User.handle_malicious_user(user, conn.remote_ip)
      assert user.id == user.ban_info.user_id
      # check that ip and hostname were banned
      assert user.malicious_score == 4.0416
    end
  end

  describe "register/2" do
    test "user is registered and returns newly registered user with 200", %{conn: conn} do
      register_attrs = %{
        username: "registertest",
        email: "registertest@test.com",
        password: "password"
      }

      conn = post(conn, Routes.user_path(conn, :register, register_attrs))
      {:ok, registered_user} = User.by_username(register_attrs.username)
      assert registered_user.id == json_response(conn, 200)["id"]
    end

    test "errors with 400 when email is already taken", %{conn: conn, user_attrs: existing_user_attrs} do
      conn = post(conn, Routes.user_path(conn, :register, existing_user_attrs))

      assert %{"error" => "Bad Request", "message" => "Email has already been taken"} =
               json_response(conn, 400)
    end

    @tag :authenticated
    test "errors with 400 when user is logged in", %{conn: conn, user_attrs: authed_user_attrs} do
      conn = post(conn, Routes.user_path(conn, :register, authed_user_attrs))

      assert %{
               "error" => "Bad Request",
               "message" => "Cannot register a new account while logged in"
             } = json_response(conn, 400)
    end

    test "errors with 400 when username is missing", %{conn: conn} do
      blank_username_attrs = %{username: "", email: "blankusernametest@test.com", password: "password"}
      conn = post(conn, Routes.user_path(conn, :register, blank_username_attrs))

      assert %{"error" => "Bad Request", "message" => "Username can't be blank"} =
               json_response(conn, 400)
    end

    test "errors with 400 when password is missing", %{conn: conn} do
      blank_password_attrs = %{username: "blankpasswordtest", email: "blankpasswordtest@test.com", password: ""}
      conn = post(conn, Routes.user_path(conn, :register, blank_password_attrs))

      assert %{"error" => "Bad Request", "message" => "Password can't be blank"} =
               json_response(conn, 400)
    end
  end

  describe "confirm/2" do
    test "confirms user using token", %{conn: conn, user: user} do
      # confirm user
      User
      |> Repo.get(user.id)
      |> change(%{confirmation_token: :crypto.strong_rand_bytes(20) |> Base.encode64()})
      |> Repo.update()

      # refresh user data
      {:ok, confirmed_user} = User.by_username(user.username)

      conn =
        post(
          conn,
          Routes.user_path(conn, :confirm, %{
            username: confirmed_user.username,
            token: confirmed_user.confirmation_token
          })
        )

      assert confirmed_user.id == json_response(conn, 200)["id"]
    end

    test "errors with 400 when user not found", %{conn: conn} do
      invalid_username_confirm = %{username: "invalidusernametest", token: 1}
      conn = post(conn, Routes.user_path(conn, :confirm, invalid_username_confirm))

      assert %{"error" => "Bad Request", "message" => "Confirmation error, account not found"} =
               json_response(conn, 400)
    end

    test "errors with 400 when token is invalid", %{conn: conn, user_attrs: user_attrs} do
      invalid_token_confirm = %{username: user_attrs.username, token: 1}
      conn = post(conn, Routes.user_path(conn, :confirm, invalid_token_confirm))

      assert %{"error" => "Bad Request", "message" => "Account confirmation error, invalid token"} =
               json_response(conn, 400)
    end
  end

  describe "login/2" do
    test "logs in a user", %{conn: conn, user: user, user_attrs: user_attrs} do
      conn = post(conn, Routes.user_path(conn, :login, user_attrs))
      assert user.id == json_response(conn, 200)["id"]
    end

    @tag :authenticated
    test "errors with 400 when user is already logged in", %{conn: conn, user_attrs: authed_user_attrs} do
      conn = post(conn, Routes.user_path(conn, :login, authed_user_attrs))

      assert %{"error" => "Bad Request", "message" => "Already logged in"} =
               json_response(conn, 400)
    end

    test "errors with 400 if user is not confirmed", %{conn: conn, user: user, user_attrs: user_attrs} do
      User
      |> Repo.get(user.id)
      |> change(%{confirmation_token: "1"})
      |> Repo.update()

      conn = post(conn, Routes.user_path(conn, :login, user_attrs))

      assert %{"error" => "Bad Request", "message" => "User account not confirmed"} =
               json_response(conn, 400)
    end

    test "errors with 403 if user is missing passhash", %{conn: conn, user: user, user_attrs: user_attrs} do
      User
      |> Repo.get(user.id)
      |> change(%{passhash: nil})
      |> Repo.update()

      conn = post(conn, Routes.user_path(conn, :login, user_attrs))

      assert %{
               "error" => "Forbidden",
               "message" => "User account migration not complete, please reset password"
             } = json_response(conn, 403)
    end

    test "errors with 400 when username is not found", %{conn: conn} do
      invalid_username_login_attrs = %{username: "invalidlogintest", password: "password"}
      conn = post(conn, Routes.user_path(conn, :login, invalid_username_login_attrs))

      assert %{"error" => "Bad Request", "message" => "Invalid credentials"} =
               json_response(conn, 400)
    end

    test "errors with 400 when password is not found", %{conn: conn} do
      invalid_password_login_attrs = %{username: "logintest", password: "1"}
      conn = post(conn, Routes.user_path(conn, :login, invalid_password_login_attrs))

      assert %{"error" => "Bad Request", "message" => "Invalid credentials"} =
               json_response(conn, 400)
    end
  end

  describe "logout/1" do
    @tag :authenticated
    test "success if user is logged out", %{conn: conn} do
      conn = delete(conn, Routes.user_path(conn, :logout))
      assert %{"success" => true} = json_response(conn, 200)
    end

    test "errors with 400 when user is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.user_path(conn, :logout))
      assert %{"error" => "Bad Request", "message" => "Not logged in"} = json_response(conn, 400)
    end
  end

  describe "authenticate/1" do
    @tag :authenticated
    test "success if current logged in user is authenticated", %{conn: conn, user_attrs: authed_user_attrs} do
      conn = get(conn, Routes.user_path(conn, :authenticate))
      {:ok, user} = User.by_username(authed_user_attrs.username)
      assert user.id == json_response(conn, 200)["id"]
    end

    test "errors with 401 when user is not logged in but trying to authenticate", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :authenticate))

      assert %{"error" => "Unauthorized", "message" => "No resource found", "status" => 401} =
               json_response(conn, 401)
    end
  end

  defp ban_user(%{user: user}) do
    {:ok, banned_user} = Ban.ban(user, NaiveDateTime.utc_now())
    {:ok, banned_user: banned_user}
  end
end
