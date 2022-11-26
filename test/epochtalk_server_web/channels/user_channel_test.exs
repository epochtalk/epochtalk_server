defmodule EpochtalkServerWeb.UserChannelTest do
  use EpochtalkServerWeb.ChannelCase
  alias EpochtalkServer.Session
  alias EpochtalkServer.Models.User
  alias EpochtalkServerWeb.UserSocket
  alias EpochtalkServerWeb.UserChannel

  describe "join channels with authentication" do
    setup do
      {:ok, user} = User.create(%{username: "test", email: "test@test.com", password: "password"})
      conn = Phoenix.ConnTest.build_conn()
      {:ok, user, token, _conn} = Session.create(user, false, conn)

      socket =
        UserSocket
        |> socket("user:#{user.id}", %{guardian_default_token: token, user_id: user.id})

      %{socket: socket}
    end

    test "successful join of 'user:public' channel", %{socket: socket} do
      assert socket.joined == false
      {:ok, _payload, socket} = subscribe_and_join(socket, UserChannel, "user:public")
      assert socket.joined == true
      assert socket.id == "user:#{socket.assigns.user_id}"
    end

    test "successful join of 'user:role' channel", %{socket: socket} do
      assert socket.joined == false
      {:ok, _payload, socket} = subscribe_and_join(socket, UserChannel, "user:role")
      assert socket.joined == true
      assert socket.id == "user:#{socket.assigns.user_id}"
    end

    test "successful join of 'user:<user_id>' channel", %{socket: socket} do
      assert socket.joined == false

      {:ok, _payload, socket} =
        subscribe_and_join(socket, UserChannel, "user:#{socket.assigns.user_id}")

      assert socket.joined == true
      assert socket.id == "user:#{socket.assigns.user_id}"
    end
  end

  describe "join channels without authentication" do
    setup do
      %{socket: socket(UserSocket, nil, %{})}
    end

    test "successful join of 'user:public' channel", %{socket: socket} do
      assert socket.joined == false
      {:ok, _payload, socket} = subscribe_and_join(socket, UserChannel, "user:public")
      assert socket.joined == true
      assert socket.id == nil
    end

    test "return :error tuple upon join of 'user:role' channel", %{socket: socket} do
      assert socket.joined == false

      assert {:error, %{reason: "unauthorized, cannot join 'user:role' channel"}} ==
               subscribe_and_join(socket, UserChannel, "user:role")
    end

    test "return :error tuple upon join of 'user:1' channel", %{socket: socket} do
      assert socket.joined == false

      assert {:error, %{reason: "unauthorized, cannot join 'user:1' channel"}} ==
               subscribe_and_join(socket, UserChannel, "user:1")
    end
  end

  describe "client message is_online to 'user:public' channel" do
    setup do
      {:ok, user} = User.create(%{username: "test", email: "test@test.com", password: "password"})
      conn = Phoenix.ConnTest.build_conn()
      {:ok, user, token, _conn} = Session.create(user, false, conn)

      {:ok, _payload, socket} =
        UserSocket
        |> socket("user:#{user.id}", %{guardian_default_token: token, user_id: user.id})
        |> subscribe_and_join(UserChannel, "user:public")

      %{socket: socket, user_id: user.id}
    end

    test "returns %{user_id: <user_id>, online: true} for logged in user", %{
      socket: socket,
      user_id: user_id
    } do
      ref = push(socket, "is_online", %{"user_id" => user_id})
      assert_reply ref, :ok, %{id: ^user_id, online: true}
    end

    test "returns %{user_id: <user_id>, online: false} for offline user", %{
      socket: socket,
      user_id: user_id
    } do
      user_id = user_id + :rand.uniform(9999)
      ref = push(socket, "is_online", %{"user_id" => user_id})
      assert_reply ref, :ok, %{id: ^user_id, online: false}
    end
  end
end
