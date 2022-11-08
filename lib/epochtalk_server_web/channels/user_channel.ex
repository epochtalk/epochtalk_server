defmodule EpochtalkServerWeb.UserChannel do
  use EpochtalkServerWeb, :channel
  @moduledoc """
  Handles `User` websocket channel. Used to broadcast events like
  reauthenticate and logout.
  """
  # intercept ["logout"]


  @doc """
  Handles joining of `user:<user_id>` channel, checks that user is authenticated.
  This is a channel private to the specific `User` used to broadcast events
  such as reauthenticate or logout.
  """
  @impl true
  def join("user:" <> _user_id, _payload, socket) do
    if authorized?(socket) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @doc """
  Handles joining of `user:role` channel. Message is broadcast on this channel when
  a role is updated, this tells the client to reauthenticate to fetch new roles. Message
  contains the `lookup` of the role, if the client will check the user's roles for the
  role `lookup` and reauthenticate if necessary.
  """
  @impl true
  def join("user:role", _payload, socket) do
    if authorized?(socket) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # # Channels can be used in a request/response fashion
  # # by sending replies to requests from the client
  # @impl true
  # def handle_in("ping", payload, socket) do
  #   {:reply, {:ok, payload}, socket}
  # end

  # # It is also common to receive messages from the client and
  # # broadcast to everyone in the current topic (user:lobby).
  # @impl true
  # def handle_in("shout", payload, socket) do
  #   broadcast(socket, "shout", payload)
  #   {:noreply, socket}
  # end

  # @impl true
  # def handle_in("reauthenticate", payload, socket) do
  #   broadcast(socket, "reauthenticate", payload)
  #   {:noreply, socket}
  # end

  # @impl true
  # def handle_out("logout", payload, socket) do
  #   IO.inspect socket.join_ref
  #   push(socket, "logout", payload)
  #   {:noreply, socket}
  # end

  # Add authorization logic here as required.
  defp authorized?(socket), do: Guardian.Phoenix.Socket.authenticated?(socket)
end
