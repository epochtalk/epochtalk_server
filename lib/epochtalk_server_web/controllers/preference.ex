defmodule EpochtalkServerWeb.Controllers.Preference do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Preference` related API requests
  """
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServer.Models.Preference
  alias EpochtalkServerWeb.ErrorHelpers

  @doc """
  Used to retrieve preferences of a specific `User`
  """
  def preferences(conn, _attrs) do
    with {:auth, %{} = user} <- {:auth, Guardian.Plug.current_resource(conn)},
         do: render(conn, :preferences, preferences: Preference.by_user_id(user.id)),
         else:
           ({:auth, nil} ->
              ErrorHelpers.render_json_error(conn, 400, "Not logged in, cannot fetch preferences"))
  end
end
