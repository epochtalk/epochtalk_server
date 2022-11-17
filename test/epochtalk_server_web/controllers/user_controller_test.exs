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

  describe "check username and email" do
    setup [:create_user]

    test "check if username is taken", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_path(conn, :username, user.username))
      assert %{"found" => true} = json_response(conn, 200)
    end

    test "check if email is taken", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_path(conn, :email, user.email))
      assert %{"found" => true} = json_response(conn, 200)
    end
  end

  describe "ban" do
    setup [:create_user]

    test "correctly ban user", %{user: user} do
      {:ok, user} = Ban.ban(user)
      assert user.id == user.ban_info.user_id
    end
  end

  describe "unban" do
    setup [:create_user]

    setup %{user: user} do
      {:ok, user} = Ban.ban(user, NaiveDateTime.utc_now())
      {:ok, user: user}
    end

    test "correctly unban user", %{user: user} do
      {:ok, user} = Ban.unban(user)
      assert nil == user.ban_info
    end
  end

  describe "malicious IP" do
    setup [:create_user]

    test "renders error of malicious IP", %{conn: conn} do
      IO.inspect(Repo.all(EpochtalkServer.Models.BannedAddress))
      {:ok, user} = User.by_username(@create_attrs.username)
      {:ok, user} = User.handle_malicious_user(user, conn.remote_ip)
      assert user.id == user.ban_info.user_id
      # check that ip and hostname were banned
      assert user.malicious_score == 4.0416
    end
  end

  describe "register" do
    test "new user", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :register, @register_attrs))
      {:ok, user} = User.by_username(@register_attrs.username)
      assert user.id == json_response(conn, 200)["id"]
    end

    test "renders errors when email is taken", %{conn: conn} do
      User.create(@register_attrs)
      conn = post(conn, Routes.user_path(conn, :register, @register_attrs))

      assert %{"error" => "Bad Request", "message" => "Email has already been taken"} =
               json_response(conn, 400)
    end

    @tag :authenticated
    test "renders errors when user is already authenticated", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :register, @auth_attrs))

      assert %{
               "error" => "Bad Request",
               "message" => "Cannot register a new account while logged in"
             } = json_response(conn, 400)
    end

    test "renders errors when username is missing", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :register, @invalid_username_attrs))

      assert %{"error" => "Bad Request", "message" => "Username can't be blank"} =
               json_response(conn, 400)
    end

    test "renders errors when password is missing", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :register, @invalid_password_attrs))

      assert %{"error" => "Bad Request", "message" => "Password can't be blank"} =
               json_response(conn, 400)
    end
  end

  describe "confirm" do
    setup [:create_user]

    test "confirm", %{conn: conn} do
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

    test "renders errors when user not found", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :confirm, @confirm_invalid_username))

      assert %{"error" => "Bad Request", "message" => "Confirmation error, account not found"} =
               json_response(conn, 400)
    end

    test "renders errors when token is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :confirm, @confirm_invalid_token))

      assert %{"error" => "Bad Request", "message" => "Account confirmation error, invalid token"} =
               json_response(conn, 400)
    end
  end

  describe "login" do
    setup [:create_login_user]

    test "login", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :login, @login_attrs))
      {:ok, user} = User.by_username(@login_attrs.username)
      assert user.id == json_response(conn, 200)["id"]
    end

    @tag :authenticated
    test "renders error when user is already logged in", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :login, @auth_attrs))

      assert %{"error" => "Bad Request", "message" => "Already logged in"} =
               json_response(conn, 400)
    end

    test "renders error if user cannot be found", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :login, @create_attrs))

      assert %{"error" => "Bad Request", "message" => "Invalid credentials"} =
               json_response(conn, 400)
    end

    test "renders error if user not confirmed", %{conn: conn} do
      {:ok, user} = User.by_username(@login_attrs.username)

      User
      |> Repo.get(user.id)
      |> change(%{confirmation_token: "1"})
      |> Repo.update()

      conn = post(conn, Routes.user_path(conn, :login, @login_attrs))

      assert %{"error" => "Bad Request", "message" => "User account not confirmed"} =
               json_response(conn, 400)
    end

    test "renders error if user missing passhash", %{conn: conn} do
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

    test "renders error when invalid username", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :login, @invalid_login_username_attrs))

      assert %{"error" => "Bad Request", "message" => "Invalid credentials"} =
               json_response(conn, 400)
    end

    test "renders error when missing password", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :login, @invalid_login_password_attrs))

      assert %{"error" => "Bad Request", "message" => "Invalid credentials"} =
               json_response(conn, 400)
    end
  end

  describe "logout" do
    @tag :authenticated
    test "logout success", %{conn: conn} do
      conn = delete(conn, Routes.user_path(conn, :logout))
      assert %{"success" => true} = json_response(conn, 200)
    end

    test "renders error when user is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.user_path(conn, :logout))
      assert %{"error" => "Bad Request", "message" => "Not logged in"} = json_response(conn, 400)
    end
  end

  describe "authenticate" do
    @tag :authenticated
    test "authenticate success", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :authenticate))
      {:ok, user} = User.by_username(@auth_attrs.username)
      assert user.id == json_response(conn, 200)["id"]
    end

    test "renders error when user is not loegged in", %{conn: conn} do
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
