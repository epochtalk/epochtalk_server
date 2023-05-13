defmodule EpochtalkServerWeb.ConfigurationController do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Configuration` related API requests
  """

  @doc """
  Used to render `/config.js` which is used by the Epochtalk Vue Frontend
  """
  def config(conn, _attrs) do
    conn
    |> Phoenix.Controller.put_format(:js)
    |> put_resp_content_type("content-type", "text/javascript")
    |> render(:config, config: Application.get_env(:epochtalk_server, :frontend_config))
  end
end
