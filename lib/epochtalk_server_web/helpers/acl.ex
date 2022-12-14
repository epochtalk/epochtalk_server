defmodule EpochtalkServerWeb.Helpers.ACL do
  alias EpochtalkServer.Models.Role
  alias EpochtalkServerWeb.CustomErrors.InvalidPermission
  @moduledoc """
  Helper for checking authenticated user's permissions.
  """

  def allow(conn, permission_path), do: allow(conn, permission_path, nil)
  def allow(conn, permission_path, error_msg) do
    user = EpochtalkServer.Auth.Guardian.Plug.current_resource(conn)
    authed_permissions = Role.get_masked_permissions(user.roles)
    path_list = String.split(permission_path, ".") # convert path to array
    path_list = if tl(path_list) != "allow", # append "allow" to array
      do: path_list ++ ["allow"],
      else: path_list
    has_permission = Kernel.get_in(authed_permissions, path_list)
    if has_permission,
      do: :ok,
      else: raise(InvalidPermission, message: error_msg)
  end
end
