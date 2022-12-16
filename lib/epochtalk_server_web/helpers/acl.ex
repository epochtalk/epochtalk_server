defmodule EpochtalkServerWeb.Helpers.ACL do
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.User
  alias EpochtalkServerWeb.CustomErrors.InvalidPermission

  @moduledoc """
  Helper for checking authenticated user's permissions.
  """

  @doc """
  Checks if authenticated `User` is allowed to perform a specific action.

  Compares a mask all of user's roles into a masked permission set and checks
  if that permission set contains the specified `permission_path`.

  Raises `CustomErrors.InvalidPermission` exception if the `User` does not have
  the proper permissions.

  TODO(akinsey): figure out how to typespec this function. The requirement that
  dialyzer has to use a valid authenticated connection, is preventing it from reaching
  `:ok`. Currently when spec is added, dialyzer will only reach the `raise`
  """
  def allow!(%Plug.Conn{} = conn, permission_path), do: allow!(conn, permission_path, nil)

  def allow!(%User{} = user, permission_path),
    do: allow!(%Plug.Conn{private: %{guardian_default_resource: user}}, permission_path, nil)

  @doc """
  Same as `ACL.allow!/2` but allows a custom error message to be raised if the
  `User` does not have the proper permissions.
  """
  def allow!(
        %Plug.Conn{private: %{guardian_default_resource: user}} = _conn,
        permission_path,
        error_msg
      ) do
    authed_permissions = Role.get_masked_permissions(user.roles || [])
    # convert path to array
    path_list = String.split(permission_path, ".")
    # append "allow" to array
    path_list =
      if List.last(path_list) != "allow",
        do: path_list ++ ["allow"],
        else: path_list

    has_permission = Kernel.get_in(authed_permissions, path_list)
    if !has_permission, do: raise(InvalidPermission, message: error_msg)
    :ok
  end

  def allow!(
        %User{} = user,
        permission_path,
        error_msg
      ),
      do:
        allow!(
          %Plug.Conn{private: %{guardian_default_resource: user}},
          permission_path,
          error_msg
        )
end
