defmodule EpochtalkServerWeb.UserChannel do
  use EpochtalkServerWeb, :channel
  @moduledoc """
  Handles `User` websocket channel. Used to broadcast events like
  reauthenticate and logout.
  """

  # Handles joining of `user:public` channel. Message is broadcast on this channel when
  # a `MOTD` is updated, this tells the client to fetch the MOTD.
  def join("user:public", _payload, socket), do: {:ok, socket}

  # Handles joining of `user:role` channel. Message is broadcast on this channel when
  # a role is updated, this tells the client to reauthenticate to fetch new roles. Message
  # contains the `lookup` of the role, if the client will check the user's roles for the
  # role `lookup` and reauthenticate if necessary.
  @impl true
  def join("user:role", _payload, socket) do
    if authorized?(socket) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Handles joining of `user:<user_id>` channel, checks that user is authenticated.
  # This is a channel private to the specific `User` used to broadcast events
  # such as reauthenticate or logout.
  @impl true
  def join("user:" <> _user_id, _payload, socket) do
    if authorized?(socket) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Add authorization logic here as required.
  defp authorized?(socket), do: Guardian.Phoenix.Socket.authenticated?(socket)
end
