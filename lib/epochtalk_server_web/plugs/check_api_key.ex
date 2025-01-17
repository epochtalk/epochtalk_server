defmodule EpochtalkServerWeb.Plugs.CheckAPIKey do
  @moduledoc """
  Plug that tracks user IP address for PUT POST or PATCH operations
  """
  use Plug.Builder
  import Plug.Conn

  @env Mix.env()
  @methods ~w(GET POST PUT PATCH)

  plug(:check_api_key)

  @doc """
  Validates and checks API key sent from frontend against one stored on backend
  """
  def check_api_key(conn, _opts) do
    %{method: method} = conn

    if method in @methods and @env != :test do
      try_verify(conn)
    else
      conn
    end
  end

  defp try_verify(conn) do
    config = Application.get_env(:epochtalk_server, :frontend_config)
    api_key = config[:api_key]
    [req_api_key] = get_req_header(conn, "api-key")

    if api_key == req_api_key,
      do: conn,
      else: raise(Plug.BadRequestError)
  end
end
