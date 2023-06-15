defmodule Test.EpochtalkServerWeb.UserSocket do
  use Test.Support.ChannelCase
  alias EpochtalkServerWeb.UserSocket
  alias EpochtalkServer.Auth.Guardian

  describe "connect/3" do
    test "given invalid JWT, returns :error" do
      assert connect(UserSocket, %{token: "bad_token"}) == :error
    end

    test "given valid JWT without backing user, returns :error" do
      {:ok, token, _claims} = Guardian.encode_and_sign(%{user_id: :rand.uniform(9999)})
      assert connect(UserSocket, %{token: token}) == :error
    end

    @tag :authenticated
    test "given valid JWT with backing user, returns authenticated socket", %{
      user_id: user_id,
      token: token
    } do
      {:ok, socket} = connect(UserSocket, %{token: token})
      assert socket.assigns.user_id == user_id
      assert socket.assigns.guardian_default_token == token
    end

    test "with anonymous connection, returns unauthenticated socket" do
      {:ok, socket} = connect(UserSocket, %{})
      assert socket.assigns == %{}
    end
  end
end
