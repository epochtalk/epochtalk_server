defmodule Test.EpochtalkServerWeb.Controllers.User do
  use Test.Support.ConnCase, async: true
  # for mocking,
  use Mimic
  import Ecto.Changeset
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Ban
  alias EpochtalkServer.Repo

  describe "username/2" do
    test "when username is taken, found is true", %{conn: conn, users: %{user: user}} do
      response =
        conn
        |> get(Routes.user_path(conn, :username, user.username))
        |> json_response(200)

      assert response["found"] == true
    end

    test "when username is not taken, found is false", %{conn: conn} do
      response =
        conn
        |> get(Routes.user_path(conn, :username, "false_username"))
        |> json_response(200)

      assert response["found"] == false
    end
  end

  describe "email/2" do
    test "when email is taken, found is true", %{conn: conn, users: %{user: user}} do
      response =
        conn
        |> get(Routes.user_path(conn, :email, user.email))
        |> json_response(200)

      assert response["found"] == true
    end

    test "when email is not taken, found is false", %{conn: conn} do
      invalid_email = "false@test.com"

      response =
        conn
        |> get(Routes.user_path(conn, :email, invalid_email))
        |> json_response(200)

      assert response["found"] == false
    end
  end

  describe "ban/1" do
    test "bans user", %{users: %{user: user}} do
      {:ok, banned_user_changeset} = Ban.ban(user)
      assert banned_user_changeset.ban_info.user_id == user.id
    end
  end

  @tag :banned
  describe "unban/1" do
    test "unbans banned user", %{users: %{user: user}} do
      {:ok, unbanned_user_changeset} = Ban.unban(user)
      assert unbanned_user_changeset.ban_info == nil
    end
  end

  @tag :malicious
  describe "handle_malicious_user/2" do
    test "populates ban_info and malicious_score if user is malicious", %{
      users: %{user: user},
      malicious_user_changeset: malicious_user_changeset
    } do
      assert malicious_user_changeset.ban_info.user_id == user.id
      # check that ip and hostname were banned
      assert malicious_user_changeset.malicious_score == 2.0416
    end
  end

  describe "register/2" do
    test "registers and returns new user", %{conn: conn} do
      register_attrs = %{
        username: "registertest",
        email: "registertest@test.com",
        password: "password"
      }

      mocked_date = ~N[2000-01-01 00:00:00.000000]
      expect(NaiveDateTime, :utc_now, fn -> mocked_date end)

      response =
        conn
        |> post(Routes.user_path(conn, :register, register_attrs))
        |> json_response(200)

      {:ok, registered_user} = User.by_username(register_attrs.username)
      assert response["id"] == registered_user.id
      assert registered_user.created_at == mocked_date |> NaiveDateTime.truncate(:second)
      assert registered_user.updated_at == mocked_date |> NaiveDateTime.truncate(:second)
    end

    test "when email is already taken, errors", %{
      conn: conn,
      user_attrs: %{user: existing_user_attrs}
    } do
      response =
        conn
        |> post(Routes.user_path(conn, :register, existing_user_attrs))
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Email has already been taken"
    end

    @tag :authenticated
    test "when user is logged in, errors", %{
      conn: conn,
      authed_user_attrs: authed_user_attrs
    } do
      response =
        conn
        |> post(Routes.user_path(conn, :register, authed_user_attrs))
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Cannot register a new account while logged in"
    end

    test "when username is missing, errors", %{conn: conn} do
      blank_username_attrs = %{
        username: "",
        email: "blankusernametest@test.com",
        password: "password"
      }

      response =
        conn
        |> post(Routes.user_path(conn, :register, blank_username_attrs))
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Username can't be blank"
    end

    test "when password is missing, errors", %{conn: conn} do
      blank_password_attrs = %{
        username: "blankpasswordtest",
        email: "blankpasswordtest@test.com",
        password: ""
      }

      response =
        conn
        |> post(Routes.user_path(conn, :register, blank_password_attrs))
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Password can't be blank"
    end
  end

  describe "confirm/2" do
    test "given a valid token, confirms user", %{conn: conn, users: %{user: user}} do
      # confirm user
      User
      |> Repo.get(user.id)
      |> change(%{confirmation_token: :crypto.strong_rand_bytes(20) |> Base.encode64()})
      |> Repo.update()

      # refresh user data
      {:ok, confirmed_user} = User.by_username(user.username)

      response =
        conn
        |> post(
          Routes.user_path(conn, :confirm, %{
            username: confirmed_user.username,
            token: confirmed_user.confirmation_token
          })
        )
        |> json_response(200)

      assert response["id"] == confirmed_user.id
    end

    test "when user is not found, errors", %{conn: conn} do
      invalid_username_confirm = %{username: "invalidusernametest", token: "(anything)"}

      response =
        conn
        |> post(Routes.user_path(conn, :confirm, invalid_username_confirm))
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Confirmation error, account not found"
    end

    test "given an invalid token, errors", %{conn: conn, user_attrs: %{user: valid_user_attrs}} do
      invalid_token = 1
      invalid_token_confirm = %{username: valid_user_attrs.username, token: invalid_token}

      response =
        conn
        |> post(Routes.user_path(conn, :confirm, invalid_token_confirm))
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Account confirmation error, invalid token"
    end
  end

  describe "login/2" do
    test "given valid credentials, logs a user in", %{
      conn: conn,
      users: %{user: user},
      user_attrs: %{user: user_attrs}
    } do
      response =
        conn
        |> post(Routes.user_path(conn, :login, user_attrs))
        |> json_response(200)

      assert response["id"] == user.id
    end

    @tag :authenticated
    test "when already logged in, errors", %{
      conn: conn,
      authed_user_attrs: authed_user_attrs
    } do
      response =
        conn
        |> post(Routes.user_path(conn, :login, authed_user_attrs))
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Already logged in"
    end

    test "when user is not confirmed, errors", %{
      conn: conn,
      users: %{user: user},
      user_attrs: %{user: user_attrs}
    } do
      User
      |> Repo.get(user.id)
      |> change(%{confirmation_token: "1"})
      |> Repo.update()

      response =
        conn
        |> post(Routes.user_path(conn, :login, user_attrs))
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "User account not confirmed"
    end

    test "given a missing passhash, errors", %{
      conn: conn,
      users: %{user: user},
      user_attrs: %{user: user_attrs}
    } do
      User
      |> Repo.get(user.id)
      |> change(%{passhash: nil})
      |> Repo.update()

      response =
        conn
        |> post(Routes.user_path(conn, :login, user_attrs))
        |> json_response(403)

      assert response["error"] == "Forbidden"
      assert response["message"] == "User account migration not complete, please reset password"
    end

    test "given invalid username, errors", %{conn: conn} do
      invalid_username_login_attrs = %{username: "invalidlogintest", password: "password"}

      response =
        conn
        |> post(Routes.user_path(conn, :login, invalid_username_login_attrs))
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Invalid credentials"
    end

    test "given invalid password, errors", %{conn: conn} do
      invalid_password_login_attrs = %{username: "logintest", password: "1"}

      response =
        conn
        |> post(Routes.user_path(conn, :login, invalid_password_login_attrs))
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Invalid credentials"
    end
  end

  describe "logout/1" do
    @tag :authenticated
    test "when logged in, logs user out", %{conn: conn} do
      response =
        conn
        |> delete(Routes.user_path(conn, :logout))
        |> json_response(200)

      assert response["success"] == true
    end

    test "when not logged in, errors", %{conn: conn} do
      response =
        conn
        |> delete(Routes.user_path(conn, :logout))
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Not logged in"
    end
  end

  describe "authenticate/1" do
    @tag :authenticated
    test "when user is authenticated, returns user info", %{
      conn: conn,
      authed_user_attrs: authed_user_attrs
    } do
      response =
        conn
        |> get(Routes.user_path(conn, :authenticate))
        |> json_response(200)

      {:ok, user} = User.by_username(authed_user_attrs.username)
      assert response["id"] == user.id
      assert Map.has_key?(response, "permissions") == true
      assert Map.has_key?(response, "roles") == true
      assert Map.has_key?(response, "token") == true
      assert Map.has_key?(response, "username") == true
    end

    test "when user is not authenticated, errors", %{conn: conn} do
      response =
        conn
        |> get(Routes.user_path(conn, :authenticate))
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
      assert response["status"] == 401
    end
  end
end
