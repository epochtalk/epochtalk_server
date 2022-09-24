defmodule EpochtalkServerWeb.GuardianErrorHandler do
  use Phoenix.Controller
  alias EpochtalkServerWeb.ErrorView

  # This is used to convert errors coming out of the guardian pipelines into a 401
  # renders error tuple from guardian pipeline into a json error response
  @behaviour Guardian.Plug.ErrorHandler
  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, _reason}, _opts) do
    message = to_string(type) |> String.replace("_", " ") |> String.capitalize
    conn
    |> put_status(401)
    |> put_view(ErrorView)
    |> render("Guardian401.json", message: message)
  end
end
