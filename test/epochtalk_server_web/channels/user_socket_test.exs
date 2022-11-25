defmodule EpochtalkServerWeb.UserSocketTest do
  use EpochtalkServerWeb.ChannelCase 
  alias EpochtalkServerWeb.UserSocket
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServer.Session
  alias EpochtalkServer.Models.User

  describe "connect/3" do
    test "returns :error for an invalid JWT" do
       assert :error = connect(UserSocket, %{token: "bad_token"})
    end

    test "returns :error for a valid JWT without backing user" do
      {:ok, token, _claims} = Guardian.encode_and_sign(%{user_id: :rand.uniform(9999)})
      assert :error = connect(UserSocket, %{token: token})
    end

    test "returns authenticated socket for a valid JWT with backing user" do
      {:ok, user} = User.create(%{username: "test", email: "test@test.com", password: "password"})
      conn = Phoenix.ConnTest.build_conn()
      {:ok, user, token, _conn} = Session.create(user, false, conn)
      user_id = user.id
      assert {:ok, %Phoenix.Socket{assigns: %{user_id: ^user_id}}} = connect(UserSocket, %{token: token})
    end

    test "returns unauthenticated socket for anonymous connections" do
      assert {:ok, %Phoenix.Socket{}} = connect(UserSocket, %{})
    end
  end
end
