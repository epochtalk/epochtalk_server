defmodule EpochtalkServerWeb.BoardController do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Board` related API requests
  """
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServer.Models.Board
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.Helpers.ACL

  @doc """
  Used to retrieve categorized boards
  """
  def by_category(conn, _attrs) do
    with {:auth, user} <- {:auth, Guardian.Plug.current_resource(conn)} do
      priority = ACL.get_user_priority(user)
      IO.inspect user
      render(conn, "categorized.json", data: priority)
    else
      {:auth, nil} ->
        ErrorHelpers.render_json_error(conn, 400, "Error, cannot fetch boards")
    end
  end
end
