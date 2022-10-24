defmodule EpochtalkServerWeb.UserSocket do
  use Phoenix.Socket

  # A Socket handler
  #
  # It's possible to control the websocket connection and
  # assign values that can be accessed by your channel topics.

  ## Channels

  channel "user:*", EpochtalkServerWeb.UserChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Guardian.Phoenix.Socket.authenticate(socket, EpochtalkServer.Auth.Guardian, token) do
      {:ok, authed_socket} ->
      user = Guardian.Phoenix.Socket.current_resource(authed_socket)
      {:ok, assign(authed_socket, :user_id, user.id)}
      {:error, _reason} -> :error
    end
  end
  def connect(_params, socket, _connect_info), do: {:ok, socket}

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Elixir.EpochtalkServerWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(%{ assigns: %{ user_id: user_id }} = _socket), do: "user:#{user_id}"
  def id(_socket), do: nil
end
