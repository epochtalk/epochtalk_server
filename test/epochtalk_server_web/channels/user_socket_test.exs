defmodule Test.EpochtalkServerWeb.UserSocket do
  use Test.Support.ChannelCase
  alias EpochtalkServerWeb.UserSocket
  alias EpochtalkServer.Auth.Guardian

  describe "connect/3" do
    test "returns :error for an invalid JWT" do
      assert :error = connect(UserSocket, %{token: "bad_token"})
    end

    test "returns :error for a valid JWT without backing user" do
      {:ok, token, _claims} = Guardian.encode_and_sign(%{user_id: :rand.uniform(9999)})
      assert :error = connect(UserSocket, %{token: token})
    end

    @tag :authenticated
    test "returns authenticated socket for a valid JWT with backing user", %{
      user_id: user_id,
      token: token
    } do
      assert {:ok, %Phoenix.Socket{assigns: %{user_id: ^user_id}}} =
               connect(UserSocket, %{token: token})
    end

    test "returns unauthenticated socket for anonymous connections" do
      assert {:ok, %Phoenix.Socket{}} = connect(UserSocket, %{})
    end
  end
end
