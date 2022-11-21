defmodule EpochtalkServerWeb.UserChannel do
  use EpochtalkServerWeb, :channel

  @moduledoc """
  Handles `User` websocket channels. These channels are used to broadcast events to
  the client. With the current design, API route can broadcast messages when an
  action is performed, this notifies the client to perform an action, such as requesting data
  from the server.

  *TODO(akinsey):* This is a direct port of the old epochtalk websocket architecture,
  there is room for improvement. For certain messages (ex: announcement) relevant data
  can be sent over the channel via the broadcast message payload. Currently, receiving
  a message triggers the client to manually make an api request for the updated data.

  ### Supported User Channels
  | channel⠀⠀⠀⠀⠀⠀   | authed  | purpose                                                              |
  | ---------------- |-------- |--------------------------------------------------------------------- |
  | `user:public`    | maybe   | All logged in and anonymous users are connected to this channel. Used to track user's online status and to broadcast MOTD announcements. |
  | `user:<user_id>` | yes     | Used to broadcast changes that affect a particular user (ex: logout) |
  | `user:role`      | yes     | Used to broadcast when a role has its permissions changed            |

  ### Client Handled Messages (messages broadcast from server)
  | broadcast message    | channel⠀⠀⠀⠀⠀⠀   | payload⠀⠀⠀⠀⠀⠀| client action                             |
  | -------------------- | ---------------- |-------------- | ----------------------------------------- |
  | `announcement`       | `user:public`    | `%{}`         | fetches MOTD announcement                 |
  | `reauthenticate`     | `user:<user_id>` | `%{}`         | reauthenticates, fetches user changes     |
  | `logout`             | `user:<user_id>` | `%{:token}`   | logout all user sessions with token       |
  | `newMessage`         | `user:<user_id>` | `%{}`         | fetches new messages/counts               |
  | `refreshMentions`    | `user:<user_id>` | `%{}`         | fetches new mentions/counts               |
  | `permissionsChanged` | `user:role`      | `%{}`         | reauthenticates, fetches new permissions  |

  ### Server Handled Messages (messages broadcast from client)
  | broadcast message    | channel          | payload⠀⠀⠀⠀⠀⠀| server action                           |
  | -------------------- | ---------------- | ------------- |---------------------------------------- |
  | `is_online`          | `user:public`    | `%{:user_id}` | replies to client with the specified user's online status |
  """
  alias EpochtalkServerWeb.Presence

  @impl true
  def join("user:public", _payload, socket), do: join_public_channel(socket)
  def join("user:role", _payload, socket), do: join_role_channel(socket)
  def join("user:" <> user_id, _payload, socket), do: join_user_channel(socket, user_id)

  @impl true
  def handle_info(:track_user_online, socket), do: track_user_online(socket)

  @impl true
  def handle_in("is_online", %{"user_id" => user_id}, socket), do: is_online(socket, user_id)

  @doc """
  Handles joining of `user:public` channel. Message is broadcast on this channel when
  a `MOTD` is updated, this tells the client to fetch the MOTD.
  """
  @spec join_public_channel(socket :: Phoenix.Socket.t()) :: {:ok, Phoenix.Socket.t()}
  def join_public_channel(socket) do
    if authorized?(socket), do: send(self(), :track_user_online)
    {:ok, socket}
  end

  @doc """
  Handles joining of `user:role` channel. Messages are broadcast on this channel when
  a roles are updated, which tell the client to reauthenticate inorder to fetch new roles.
  Messages contain the `lookup` of the updated role, the client will check the user's roles for the
  role `lookup` and reauthenticate if necessary.
  """
  @spec join_role_channel(socket :: Phoenix.Socket.t()) ::
          {:ok, Phoenix.Socket.t()} | {:error, data :: map()}
  def join_role_channel(socket) do
    if authorized?(socket) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized, cannot join 'user:role' channel"}}
    end
  end

  @doc """
  Handles joining of `user:<user_id>` channel, checks that user is authenticated.
  This is a channel private to the specific `User` used to broadcast events
  such as reauthenticate or logout.
  """
  @spec join_user_channel(socket :: Phoenix.Socket.t(), user_id :: String.t()) ::
          {:ok, Phoenix.Socket.t()} | {:error, data :: map()}
  def join_user_channel(socket, user_id) do
    if authorized?(socket) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized, cannot join 'user:#{user_id}' channel"}}
    end
  end

  @doc """
  Tracks a `User` that joins a channel using `Presence`. Currently
  used to track a `User` that joins the `user:public` channel. Used by forum
  order to keep track of online users.
  """
  @spec track_user_online(socket :: Phoenix.Socket.t()) :: {:noreply, Phoenix.Socket.t()}
  def track_user_online(socket) do
    Presence.track(socket, socket.assigns.user_id, %{})
    {:noreply, socket}
  end

  @doc """
  Handles message `is_online`, checks `user:public` channel to see if
  `User` with `user_id` is connected using Presence. Returns `user_id`
  and `online`, a boolean indicating if the `User` is connected.
  """
  @spec is_online(socket :: Phoenix.Socket.t(), user_id :: non_neg_integer) ::
          {:reply, {:ok, %{id: non_neg_integer, online: boolean}}, socket :: Phoenix.Socket.t()}
  def is_online(socket, user_id) do
    online =
      case Presence.get_by_key("user:public", user_id) do
        # empty array is returned if user isn't in channel
        [] -> false
        # meta map is returned if user is online
        _meta -> true
      end

    # Return response to client who sent `is_online` message
    {:reply, {:ok, %{id: user_id, online: online}}, socket}
  end

  defp authorized?(socket), do: Guardian.Phoenix.Socket.authenticated?(socket)
end
