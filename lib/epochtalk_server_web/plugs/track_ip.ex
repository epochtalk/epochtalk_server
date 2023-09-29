defmodule EpochtalkServerWeb.Plugs.TrackIp do
  @moduledoc """
  Plug that tracks user IP address for PUT POST or PATCH operations
  """
  use Plug.Builder
  import Plug.Conn
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServer.Models.UserIp

  @env Mix.env()
  @methods ~w(POST PUT PATCH)

  plug(:track_ip_post_request)

  @doc """
  Stores `User` IP when `User` is performing actions that modify data in the database
  """
  def track_ip_post_request(conn, _opts) do
    %{method: method} = conn

    if method in @methods and @env != :test,
      do: save_user_ip_to_database(conn),
      else: conn
  end

  defp save_user_ip_to_database(conn) do
    register_before_send(conn, fn conn ->
      user = Guardian.Plug.current_resource(conn)
      user_ip = conn.remote_ip |> :inet_parse.ntoa() |> to_string
      if user != nil, do: UserIp.track(user.id, user_ip)
      conn
    end)
  end
end
