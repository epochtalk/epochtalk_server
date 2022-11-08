defmodule EpochtalkServerWeb.UserControllerTest do
  use EpochtalkServerWeb.ConnCase, async: false
  import Ecto.Changeset
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Ban
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Auth.Guardian

  @create_attrs %{username: "createtest", email: "createtest@test.com", password: "password"}

  @register_attrs %{username: "registertest", email: "registertest@test.com", password: "password"}

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
      {:ok, user} = Ban.ban(user, NaiveDateTime.utc_now)
      {:ok, user: user}
    end

    test "correctly unban user", %{user: user} do
      {:ok, user} = Ban.unban(user)
      assert nil == user.ban_info
    end
  end

  describe "malicious IP" do
    setup [:create_user]

    # TODO(crod) Figure out an IP address to test malicious score for banning a user
    test "renders error of malicious IP", %{conn: conn} do
      {:ok, user} = User.by_username(@create_attrs.username)
      {:ok, user} = User.handle_malicious_user(user, conn.remote_ip)
      assert user.id == user.ban_info.user_id
    end
  end

  describe "register" do
    test "new user", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :register, @register_attrs))
      {:ok, user} = User.by_username(@register_attrs.username)
      id = user.id
      assert %{"id" => ^id} = json_response(conn, 200)
    end

    test "renders errors when email is taken", %{conn: conn} do
      User.create(@register_attrs)
      conn = post(conn, Routes.user_path(conn, :register, @register_attrs))
      assert %{"message" => "Email has already been taken"} = json_response(conn, 400)
    end

    # TODO(crod): Figure out how to get past recycling for testing when user is logged in
    # test "renders errors when user is already authenticated", %{conn: conn} do
    #   user = User.create(@register_login_attrs)
    #   login_conn = post(conn, Routes.user_path(conn, :login, @register_login_attrs))
    #   IO.puts "auth #{inspect(Guardian.Plug.authenticated?(login_conn))}"
    #   IO.puts "conn #{inspect(login_conn)}"

    #   register_conn = post(conn, Routes.user_path(login_conn, :register, @register_login_attrs))
    #   IO.puts "auth #{inspect(Guardian.Plug.authenticated?(register_conn))}"
    #   IO.puts "conn #{inspect(register_conn)}"
    # end

    test "renders errors when username is missing", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :register, @invalid_username_attrs))
      assert %{"message" => "Username can't be blank"} = json_response(conn, 400)
    end

    test "renders errors when password is missing", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :register, @invalid_password_attrs))
      assert %{"message" => "Password can't be blank"} = json_response(conn, 400)
    end
  end

  describe "confirm" do
    setup [:create_user]

    test "confirm", %{conn: conn} do
      {:ok, user} = User.by_username(@create_attrs.username)
      User
      |> Repo.get(user.id)
      |> change(%{ confirmation_token: :crypto.strong_rand_bytes(20) |> Base.encode64 })
      |> Repo.update
      {:ok, user} = User.by_username(@create_attrs.username)
      conn = post(conn, Routes.user_path(conn, :confirm, %{username: user.username, token: user.confirmation_token}))
      id = user.id
      assert %{"id" => ^id} = json_response(conn, 200)
    end

    test "renders errors when user not found", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :confirm, @confirm_invalid_username))
      assert %{"message" => "Confirmation error, account not found"} = json_response(conn, 400)
    end

    test "renders errors when token is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :confirm, @confirm_invalid_token))
      assert %{"message" => "Account confirmation error, invalid token"} = json_response(conn, 400)
    end
  end

  describe "login" do
    setup [:create_login_user]

    test "login", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :login, @login_attrs))
      {:ok, user} = User.by_username(@login_attrs.username)
      id = user.id
      assert %{"id" => ^id} = json_response(conn, 200)
    end

    test "renders error when invalid username", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :login, @invalid_login_username_attrs))
      assert %{"message" => "Invalid credentials"} = json_response(conn, 400)
    end

    test "renders error when missing password", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :login, @invalid_login_password_attrs))
      assert %{"message" => "Invalid credentials"} = json_response(conn, 400)
    end

    test "renders error if user cannot be found", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :login, @create_attrs))
      assert %{"message" => "Invalid credentials"} = json_response(conn, 400)
    end

    test "renders error if user not confirmed", %{conn: conn} do
      {:ok, user} = User.by_username(@login_attrs.username)
      User
      |> Repo.get(user.id)
      |> change(%{ confirmation_token: "1" })
      |> Repo.update
      conn = post(conn, Routes.user_path(conn, :login, @login_attrs))
      assert %{"message" => "User account not confirmed"} = json_response(conn, 400)
    end

    test "renders error if user missing passhash", %{conn: conn} do
      {:ok, user} = User.by_username(@login_attrs.username)
      User
      |> Repo.get(user.id)
      |> change(%{ passhash: nil })
      |> Repo.update
      conn = post(conn, Routes.user_path(conn, :login, @login_attrs))
      assert %{"message" => "User account migration not complete, please reset password"} = json_response(conn, 403)
    end
  end

  describe "logout" do
    setup [:create_login_user]

    setup %{conn: conn} do
      login_conn = post(conn, Routes.user_path(conn, :login, @login_attrs))
      {:ok, conn: login_conn}
    end

    test "logout", %{conn: conn} do
      assert true == Guardian.Plug.authenticated?(conn)
      conn = Guardian.Plug.sign_out(conn)
      {:ok, user} = User.by_username(@login_attrs.username)
      id = user.id
      assert %{"id" => ^id} = json_response(conn, 200)
    end

    test "authenticate", %{conn: conn} do
      assert true == Guardian.Plug.authenticated?(conn)
      {:ok, user} = User.by_username(@login_attrs.username)
      assert Guardian.Plug.current_resource(conn).user_id == user.id
    end

    # TODO(crod): Figure out how to get past recycling for testing user_controller.logout
    # test "logout", %{conn: conn} do
    #   login_conn = post(conn, Routes.user_path(conn, :login, @login_attrs))
    #   IO.puts "Auth from test conn: #{inspect(conn)}"
    #   IO.puts "Auth from test current_token: #{inspect(Guardian.Plug.current_token(conn))}"
    #   IO.puts "Auth from test current_resource: #{inspect(Guardian.Plug.current_resource(conn))}"
    #   saved_assigns = conn.assigns
    #   saved_private = conn.private
    #   saved_body = conn.resp_body
    #   conn =
    #     conn
    #     |> recycle()
    #     # |> Map.put(:assigns, saved_assigns)
    #     |> Map.put(:private, saved_private)
    #     # |> Map.put(:resp_body, saved_body)
    #   IO.puts "Auth from test private: #{inspect(conn.private)}"
    #   IO.puts "Auth from test authenticated?: #{inspect(Guardian.Plug.authenticated?(conn))}"
    #   IO.puts ""

    #   logout_conn = post(conn, Routes.user_path(conn, :logout))
    #   assert %{"success" => true} = json_response(logout_conn, 200)
    # end

    # TODO(crod): Figure out how to get past recycling for testing user_controller.authenticate
    # test "authenticate", %{conn: conn} do
    #   login_conn = post(conn, Routes.user_path(conn, :login, @login_attrs))
    #   IO.puts "Auth from test: #{inspect(login_conn)}"
    #   IO.puts "Auth from test: #{inspect(Guardian.Plug.authenticated?(login_conn))}"
    #   auth_conn = get(login_conn, Routes.user_path(login_conn, :authenticate, login))
    #   IO.puts "Auth Response: #{inspect(json_response(auth_conn, 200))}"
    #   assert %{"id" => id} = json_response(auth_conn, 200)
    # end
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
