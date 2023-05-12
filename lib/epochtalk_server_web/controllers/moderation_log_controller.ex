defmodule EpochtalkServerWeb.ModerationLogController do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `ModerationLog` related API requests
  """
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServer.Models.ModerationLog
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.Helpers.Validate

  @doc """
  Used to page `ModerationLog` models for moderation log view`
  """
  def page(conn, attrs) do
    with {:auth, true} <- {:auth, Guardian.Plug.authenticated?(conn)},
         page <- Validate.cast(attrs, "page", :integer, min: 1),
         limit <- Validate.cast(attrs, "limit", :integer, min: 1),
         {:ok, moderation_logs, data} <- ModerationLog.page(attrs, page, per_page: limit) do
      render(conn, "page.json", moderation_logs: moderation_logs, pagination_data: data)
    else
      {:auth, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Not logged in, cannot page moderation log")

      {:error, data} ->
        ErrorHelpers.render_json_error(conn, 400, data)

      _ ->
        ErrorHelpers.render_json_error(conn, 500, "There was an issue getting the moderation log")
    end
  end
end
