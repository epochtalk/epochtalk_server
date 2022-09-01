defmodule EpochtalkServerWeb.AuthErrorHandler do
  import Plug.Conn

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, reason}, opts) do
    # TODO: try using error view here
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(401, inspect({type, reason}))
  end
end
