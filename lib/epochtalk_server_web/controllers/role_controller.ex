defmodule EpochtalkServerWeb.RoleController do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Role` related API requests
  """
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.Helpers.Validate
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.RolePermission
  alias EpochtalkServerWeb.Helpers.ACL

  @doc """
  Used to update a specific `Role`
  """
  def update(conn, attrs) do
    with {:auth, _user} <- {:auth, Guardian.Plug.current_resource(conn)},
         :ok <- ACL.allow!(conn, "roles.update"),
         id <- Validate.cast(attrs, "id", :integer, min: 1),
         # TODO(boka): implement validators
         priority_restrictions <- attrs["priority_restrictions"],
         permissions <- attrs["permissions"],
         {:ok, data} <-
           RolePermission.modify_by_role(%Role{
             id: id,
             permissions: permissions,
             priority_restrictions: priority_restrictions
           }) do
      render(conn, "update.json", data: data)
    else
      {:auth, nil} ->
        ErrorHelpers.render_json_error(conn, 400, "Not logged in, cannot update role")
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
