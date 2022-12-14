defmodule EpochtalkServerWeb.UserControllerTest do
  use EpochtalkServerWeb.ConnCase, async: false
  import Ecto.Changeset
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Ban
  alias EpochtalkServer.Repo

  @create_attrs %{username: "createtest", email: "createtest@test.com", password: "password"}

  @auth_attrs %{username: "authtest", email: "authtest@test.com", password: "password"}

  @register_attrs %{
    username: "registertest",
    email: "registertest@test.com",
    password: "password"
  }

  @confirm_invalid_username %{username: "blank", token: 1}
  @confirm_invalid_token %{username: "createtest", token: 1}

  @invalid_username_attrs %{username: "", email: "invalidtest@test.com", password: "password"}
  @invalid_password_attrs %{username: "invalid", email: "invalidtest@test.com", password: ""}

  @login_create_attrs %{username: "logintest", email: "logintest@test.com", password: "password"}
  @login_attrs %{username: "logintest", password: "password"}
  @invalid_login_password_attrs %{username: "logintest", password: "1"}
  @invalid_login_username_attrs %{username: "test", password: "password"}

  describe "username/2" do
    setup [:create_user]

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
    setup [:create_user]

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
    setup [:create_user]

    test "user is banned", %{user: user} do
      {:ok, user} = Ban.ban(user)
      assert user.id == user.ban_info.user_id
    end
  end

  describe "unban/1" do
    setup [:create_user]

    # Setup by banning a user first using ban/2
    setup %{user: user} do
      {:ok, user} = Ban.ban(user, NaiveDateTime.utc_now())
      {:ok, user: user}
    end

    test "user is unbanned", %{user: user} do
      {:ok, user} = Ban.unban(user)
      assert nil == user.ban_info
    end
  end

  describe "handle_malicious_user/2" do
    setup [:create_user]

    test "user is banned if malicious", %{conn: conn} do
      {:ok, user} = User.by_username(@create_attrs.username)
      {:ok, user} = User.handle_malicious_user(user, conn.remote_ip)
      assert user.id == user.ban_info.user_id
      # check that ip and hostname were banned
      assert user.malicious_score == 4.0416
    end
  end

  describe "register/2" do
    test "user is registered and returns newly registered user with 200", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :register, @register_attrs))
      {:ok, user} = User.by_username(@register_attrs.username)
      assert user.id == json_response(conn, 200)["id"]
    end

    test "errors with 400 when email is already taken", %{conn: conn} do
      User.create(@register_attrs)
      conn = post(conn, Routes.user_path(conn, :register, @register_attrs))

      assert %{"error" => "Bad Request", "message" => "Email has already been taken"} =
               json_response(conn, 400)
    end

    @tag :authenticated
    test "errors with 400 when user is logged in", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :register, @auth_attrs))

      assert %{
               "error" => "Bad Request",
               "message" => "Cannot register a new account while logged in"
             } = json_response(conn, 400)
    end

    test "errors with 400 when username is missing", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :register, @invalid_username_attrs))

      assert %{"error" => "Bad Request", "message" => "Username can't be blank"} =
               json_response(conn, 400)
    end

    test "errors with 400 when password is missing", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :register, @invalid_password_attrs))

      assert %{"error" => "Bad Request", "message" => "Password can't be blank"} =
               json_response(conn, 400)
    end
  end

  describe "confirm/2" do
    setup [:create_user]

    test "confirms user using token", %{conn: conn} do
      {:ok, user} = User.by_username(@create_attrs.username)

      User
      |> Repo.get(user.id)
      |> change(%{confirmation_token: :crypto.strong_rand_bytes(20) |> Base.encode64()})
      |> Repo.update()

      {:ok, user} = User.by_username(@create_attrs.username)

      conn =
        post(
          conn,
          Routes.user_path(conn, :confirm, %{
            username: user.username,
            token: user.confirmation_token
          })
        )

      assert user.id == json_response(conn, 200)["id"]
    end

    test "errors with 400 when user not found", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :confirm, @confirm_invalid_username))

      assert %{"error" => "Bad Request", "message" => "Confirmation error, account not found"} =
               json_response(conn, 400)
    end

    test "errors with 400 when token is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :confirm, @confirm_invalid_token))

      assert %{"error" => "Bad Request", "message" => "Account confirmation error, invalid token"} =
               json_response(conn, 400)
    end
  end

  describe "login/2" do
    setup [:create_login_user]

    test "logs in a user", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :login, @login_attrs))
      {:ok, user} = User.by_username(@login_attrs.username)
      assert user.id == json_response(conn, 200)["id"]
    end

    @tag :authenticated
    test "errors with 400 when user is already logged in", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :login, @auth_attrs))

      assert %{"error" => "Bad Request", "message" => "Already logged in"} =
               json_response(conn, 400)
    end

    test "errors with 400 if user cannot be found", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :login, @create_attrs))

      assert %{"error" => "Bad Request", "message" => "Invalid credentials"} =
               json_response(conn, 400)
    end

    test "errors with 400 if user is not confirmed", %{conn: conn} do
      {:ok, user} = User.by_username(@login_attrs.username)

      User
      |> Repo.get(user.id)
      |> change(%{confirmation_token: "1"})
      |> Repo.update()

      conn = post(conn, Routes.user_path(conn, :login, @login_attrs))

      assert %{"error" => "Bad Request", "message" => "User account not confirmed"} =
               json_response(conn, 400)
    end

    test "errors with 403 if user is missing passhash", %{conn: conn} do
      {:ok, user} = User.by_username(@login_attrs.username)

      User
      |> Repo.get(user.id)
      |> change(%{passhash: nil})
      |> Repo.update()

      conn = post(conn, Routes.user_path(conn, :login, @login_attrs))

      assert %{
               "error" => "Forbidden",
               "message" => "User account migration not complete, please reset password"
             } = json_response(conn, 403)
    end

    test "errors with 400 when username is not found", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :login, @invalid_login_username_attrs))

      assert %{"error" => "Bad Request", "message" => "Invalid credentials"} =
               json_response(conn, 400)
    end

    test "errors with 400 when password is not found", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :login, @invalid_login_password_attrs))

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
    test "success if current logged in user is authenticated", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :authenticate))
      {:ok, user} = User.by_username(@auth_attrs.username)
      assert user.id == json_response(conn, 200)["id"]
    end

    test "errors with 401 when user is not logged in but trying to authenticate", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :authenticate))

      assert %{"error" => "Unauthorized", "message" => "Unauthenticated"} =
               json_response(conn, 401)
    end
  end

  defp create_user(_) do
    {:ok, user} = User.create(@create_attrs)
    {:ok, user: user}
  end

  defp create_login_user(_) do
    {:ok, user} = User.create(@login_create_attrs)
    {:ok, user: user}
  end
end
