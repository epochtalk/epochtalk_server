defmodule EpochtalkServerWeb.UserChannelTest do
  use EpochtalkServerWeb.ChannelCase

  # TODO(akinsey): Improve testing for sockets
  setup do
    {:ok, _, socket} =
      EpochtalkServerWeb.UserSocket
      |> socket("user_id", %{user_id: 1})
      |> subscribe_and_join(EpochtalkServerWeb.UserChannel, "user:public")

    %{socket: socket}
  end

  test "is_online replies with online false", %{socket: socket} do
    ref = push(socket, "is_online", %{"user_id" => 2})
    assert_reply ref, :ok, %{id: 2, online: false}
  end
end
