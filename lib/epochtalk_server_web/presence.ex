defmodule EpochtalkServerWeb.Presence do
  use Phoenix.Presence,
    otp_app: :my_app,
    pubsub_server: EpochtalkServer.PubSub

  @moduledoc """
  This module is used to track `User` presence in websocket channels. Currently used
  by the `user:public` channel to check if a `User` is online.
  """
end
