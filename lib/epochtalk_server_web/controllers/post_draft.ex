defmodule EpochtalkServerWeb.Controllers.PostDraft do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller for `PostDraft` related API requests
  """
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServer.Models.PostDraft

  @doc """
  Used to upsert a specific `PostDraft`

  Returns `PostDraft` on success
  """
  def upsert(conn, attrs) do
    with {:auth, %{} = user} <- {:auth, Guardian.Plug.current_resource(conn)},
         {:ok, draft_data} <- PostDraft.upsert(user.id, attrs) do
      render(conn, :upsert, %{draft_data: draft_data, user_id: user.id})
    else
      {:auth, nil} ->
        ErrorHelpers.render_json_error(conn, 403, "Not logged in, cannot upsert post draft")

      {:error, data} ->
        ErrorHelpers.render_json_error(conn, 400, data)
    end
  end

  @doc """
  Get `PostDraft` by `User` id
  """
  def by_user_id(conn, _) do
    with {:auth, %{} = user} <- {:auth, Guardian.Plug.current_resource(conn)},
         draft_data <- PostDraft.by_user_id(user.id) do
      render(conn, :by_user_id, %{draft_data: draft_data, user_id: user.id})
    else
      {:auth, nil} ->
        ErrorHelpers.render_json_error(conn, 403, "Not logged in, cannot get post draft")
    end
  end
end
