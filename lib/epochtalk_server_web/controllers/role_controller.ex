defmodule EpochtalkServerWeb.RoleController do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Role` related API requests
  """
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.RolePermission
  alias EpochtalkServerWeb.Helpers.ACL

  @doc """
  Used to update a specific `Role`

  Returns id of `Role` on success
  """
  def update(conn, attrs) do
    with {:auth, _user} <- {:auth, Guardian.Plug.current_resource(conn)},
         :ok <- ACL.allow!(conn, "roles.update"),
         {:ok, _role_permission_data} <- RolePermission.modify_by_role(attrs),
         {:ok, _role_data} <- Role.update(attrs) do
      render(conn, "update.json", data: attrs["id"])
    else
      {:auth, nil} ->
        ErrorHelpers.render_json_error(conn, 400, "Not logged in, cannot update role")

      {:error, data} ->
        ErrorHelpers.render_json_error(conn, 400, data)
    end
  end

  @doc """
  Get all `Role`s
  """
  def all(conn, _) do
    with {:auth, _user} <- {:auth, Guardian.Plug.current_resource(conn)},
         data <- Role.all() do
      render(conn, "roles.json", data: data)
    else
      {:auth, nil} ->
        ErrorHelpers.render_json_error(conn, 400, "Not logged in, cannot get roles")
    end
  end
end
