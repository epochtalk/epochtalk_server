defmodule Test.EpochtalkServerWeb.UserChannel do
  use Test.Support.ChannelCase
  alias EpochtalkServerWeb.UserSocket
  alias EpochtalkServerWeb.UserChannel

  describe "websocket channel 'user:public'" do
    @tag authenticated: "user:public"
    test "when authenticated, joins", %{socket: socket} do
      assert socket.joined == true
      assert socket.id == "user:#{socket.assigns.user_id}"
    end

    test "when not authenticated, does not join" do
      socket = socket(UserSocket, nil, %{})
      assert socket.joined == false
      assert {:ok, _payload, socket} = subscribe_and_join(socket, UserChannel, "user:public")
      assert socket.joined == true
      assert socket.id == nil
    end

    @tag authenticated: "user:public"
    test "when user is online, server responds to 'is_online' message with %{user_id: <user_id>, online: true}",
         %{
           socket: socket,
           user_id: user_id
         } do
      ref = push(socket, "is_online", %{"user_id" => user_id})
      assert_reply ref, :ok, %{id: ^user_id, online: true}
    end

    @tag authenticated: "user:public"
    test "when user is not online, server responds to 'is_online' message with %{user_id: <user_id>, online: false}",
         %{
           socket: socket,
           user_id: user_id
         } do
      user_id = user_id + :rand.uniform(9999)
      ref = push(socket, "is_online", %{"user_id" => user_id})
      assert_reply ref, :ok, %{id: ^user_id, online: false}
    end

    @tag authenticated: "user:public"
    test "with motd payload, server broadcasts 'announcement' message", %{socket: socket} do
      assert :ok = broadcast_from(socket, "announcement", %{motd: "message"})
      assert_push "announcement", %{motd: "message"}
      refute_push "announcement", %{motd: "message"}
    end
  end

  describe "websocket channel 'user:role'" do
    @tag authenticated: "user:role"
    test "with authentication, joins", %{socket: socket} do
      assert socket.joined == true
      assert socket.id == "user:#{socket.assigns.user_id}"
    end

    test "without authentication, errors" do
      socket = socket(UserSocket, nil, %{})
      assert socket.joined == false

      assert {:error, %{reason: "unauthorized, cannot join 'user:role' channel"}} ==
               subscribe_and_join(socket, UserChannel, "user:role")
    end

    @tag authenticated: "user:role"
    test "with lookup payload, server broadcasts 'permissionsChanged' message", %{
      socket: socket
    } do
      assert :ok = broadcast_from(socket, "permissionsChanged", %{lookup: "user"})
      assert_push "permissionsChanged", %{lookup: "user"}
      refute_push "permissionsChanged", %{lookup: "user"}
    end
  end

  describe "websocket channel 'user:<user_id>'" do
    @tag authenticated: "user:<user_id>"
    test "with authentication, joins", %{socket: socket} do
      assert socket.joined == true
      assert socket.id == "user:#{socket.assigns.user_id}"
    end

    test "without authentication, errors" do
      socket = socket(UserSocket, nil, %{})
      assert socket.joined == false

      assert {:error, %{reason: "unauthorized, cannot join 'user:1' channel"}} ==
               subscribe_and_join(socket, UserChannel, "user:1")
    end

    @tag authenticated: "user:<user_id>"
    test "with empty payload, broadcasts 'reauthenticate' message", %{socket: socket} do
      assert :ok = broadcast_from(socket, "reauthenticate", %{})
      assert_push "reauthenticate", %{}
      refute_push "reauthenticate", %{}
    end

    @tag authenticated: "user:<user_id>"
    test "with token payload, broadcasts 'logout' message", %{socket: socket} do
      assert :ok = broadcast_from(socket, "logout", %{token: "some_token"})
      assert_push "logout", %{token: "some_token"}
      refute_push "logout", %{token: "some_token"}
    end

    @tag authenticated: "user:<user_id>"
    test "with empty payload, broadcasts 'newMessage' message", %{socket: socket} do
      assert :ok = broadcast_from(socket, "newMessage", %{})
      assert_push "newMessage", %{}
      refute_push "newMessage", %{}
    end

    @tag authenticated: "user:<user_id>"
    test "with empty payload, broadcasts 'refreshMentions' message", %{socket: socket} do
      assert :ok = broadcast_from(socket, "refreshMentions", %{})
      assert_push "refreshMentions", %{}
      refute_push "refreshMentions", %{}
    end
  end
end
