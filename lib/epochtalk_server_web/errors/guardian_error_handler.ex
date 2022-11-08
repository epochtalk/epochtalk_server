defmodule EpochtalkServerWeb.GuardianErrorHandler do
  alias EpochtalkServerWeb.ErrorHelpers

  @doc """
  This is used to convert errors coming out of the guardian pipelines into a json error,
  Renders error tuples received from guardian pipeline into a json error response.
  """
  @behaviour Guardian.Plug.ErrorHandler
  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, _reason}, _opts) do
    # convert type atom into human readable string (ex :invalid_token -> Invalid token)
    message = to_string(type) |> String.replace("_", " ") |> String.capitalize
    ErrorHelpers.render_json_error(conn, 401, message)
  end
end
