defmodule EpochtalkServerWeb.UserChannelTest do
  use EpochtalkServerWeb.ChannelCase
  alias EpochtalkServer.Session
  alias EpochtalkServer.Models.User
  alias EpochtalkServerWeb.UserSocket
  alias EpochtalkServerWeb.UserChannel

  describe "websocket channel 'user:public'" do
    setup do
      {socket, user_id} = create_authed_socket()

      {:ok, _payload, socket} =
        socket
        |> subscribe_and_join(UserChannel, "user:public")

      %{socket: socket, user_id: user_id}
    end

    test "joins with authentication", %{socket: socket} do
      assert socket.joined == true
      assert socket.id == "user:#{socket.assigns.user_id}"
    end

    test "joins without authentication" do
      socket = socket(UserSocket, nil, %{})
      assert socket.joined == false
      assert {:ok, _payload, socket} = subscribe_and_join(socket, UserChannel, "user:public")
      assert socket.joined == true
      assert socket.id == nil
    end

    test "server responds to 'is_online' message with %{user_id: <user_id>, online: true} for online user",
         %{
           socket: socket,
           user_id: user_id
         } do
      ref = push(socket, "is_online", %{"user_id" => user_id})
      assert_reply ref, :ok, %{id: ^user_id, online: true}
    end

    test "server responds to 'is_online' message with %{user_id: <user_id>, online: false} for offline user",
         %{
           socket: socket,
           user_id: user_id
         } do
      user_id = user_id + :rand.uniform(9999)
      ref = push(socket, "is_online", %{"user_id" => user_id})
      assert_reply ref, :ok, %{id: ^user_id, online: false}
    end

    test "server can broadcast 'announcement' message with motd payload", %{socket: socket} do
      assert :ok = broadcast_from(socket, "announcement", %{motd: "message"})
      assert_push "announcement", %{motd: "message"}
      refute_push "announcement", %{motd: "message"}
    end
  end

  describe "websocket channel 'user:role'" do
    setup do
      {socket, _user_id} = create_authed_socket()

      {:ok, _payload, socket} =
        socket
        |> subscribe_and_join(UserChannel, "user:role")

      %{socket: socket}
    end

    test "joins with authentication", %{socket: socket} do
      assert socket.joined == true
      assert socket.id == "user:#{socket.assigns.user_id}"
    end

    test "errors without authentication" do
      socket = socket(UserSocket, nil, %{})
      assert socket.joined == false

      assert {:error, %{reason: "unauthorized, cannot join 'user:role' channel"}} ==
               subscribe_and_join(socket, UserChannel, "user:role")
    end

    test "server can broadcast 'permissionsChanged' message with lookup payload", %{
      socket: socket
    } do
      assert :ok = broadcast_from(socket, "permissionsChanged", %{lookup: "user"})
      assert_push "permissionsChanged", %{lookup: "user"}
      refute_push "permissionsChanged", %{lookup: "user"}
    end
  end

  describe "websocket channel 'user:<user_id>'" do
    setup do
      {socket, user_id} = create_authed_socket()

      {:ok, _payload, socket} =
        socket
        |> subscribe_and_join(UserChannel, "user:#{user_id}")

      %{socket: socket}
    end

    test "joins with authentication", %{socket: socket} do
      assert socket.joined == true
      assert socket.id == "user:#{socket.assigns.user_id}"
    end

    test "errors without authentication" do
      socket = socket(UserSocket, nil, %{})
      assert socket.joined == false

      assert {:error, %{reason: "unauthorized, cannot join 'user:1' channel"}} ==
               subscribe_and_join(socket, UserChannel, "user:1")
    end

    test "broadcasts 'reauthenticate' message with empty payload", %{socket: socket} do
      assert :ok = broadcast_from(socket, "reauthenticate", %{})
      assert_push "reauthenticate", %{}
      refute_push "reauthenticate", %{}
    end

    test "broadcasts 'logout' message with token payload", %{socket: socket} do
      assert :ok = broadcast_from(socket, "logout", %{token: "some_token"})
      assert_push "logout", %{token: "some_token"}
      refute_push "logout", %{token: "some_token"}
    end

    test "broadcasts 'newMessage' message with empty payload", %{socket: socket} do
      assert :ok = broadcast_from(socket, "newMessage", %{})
      assert_push "newMessage", %{}
      refute_push "newMessage", %{}
    end

    test "broadcasts 'refreshMentions' message with empty payload", %{socket: socket} do
      assert :ok = broadcast_from(socket, "refreshMentions", %{})
      assert_push "refreshMentions", %{}
      refute_push "refreshMentions", %{}
    end
  end

  defp create_authed_socket() do
    {:ok, user} = User.create(%{username: "test", email: "test@test.com", password: "password"})
    conn = Phoenix.ConnTest.build_conn()
    {:ok, user, token, _conn} = Session.create(user, false, conn)

    socket =
      UserSocket
      |> socket("user:#{user.id}", %{guardian_default_token: token, user_id: user.id})

    {socket, user.id}
  end
end
