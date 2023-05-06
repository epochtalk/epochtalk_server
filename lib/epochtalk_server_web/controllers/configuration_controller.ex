defmodule EpochtalkServerWeb.ConfigurationController do
  use EpochtalkServerWeb, :controller_old

  @moduledoc """
  Controller For `Configuration` related API requests
  """

  @doc """
  Used to render `/config.js` which is used by the Epochtalk Vue Frontend
  """
  def config(conn, _attrs) do
    conn
    |> put_resp_header("content-type", "text/javascript")
    |> render("config.js", config: Application.get_env(:epochtalk_server, :frontend_config))
  end
end
