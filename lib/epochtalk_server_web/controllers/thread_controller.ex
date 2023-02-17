defmodule EpochtalkServerWeb.ThreadController do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Thread` related API requests
  """
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.Helpers.Validate
  alias EpochtalkServerWeb.Helpers.ACL
  alias EpochtalkServer.Models.Thread

  @doc """
  Used to retrieve recent threads

  TODO(akinsey): come back to this after implementing thread and post create
  """
  def recent(conn, attrs) do
    with limit <- Validate.cast(attrs, "limit", :integer, default: 5),
         user <- Guardian.Plug.current_resource(conn),
         user_priority <- ACL.get_user_priority(conn),
         threads <- Thread.recent(user, user_priority, limit: limit) do
      render(conn, "recent.json", %{
        threads: threads
      })
    else
      _ -> ErrorHelpers.render_json_error(conn, 400, "Error, cannot fetch recent threads")
    end
  end
end
