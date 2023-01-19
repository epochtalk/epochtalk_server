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
  """
  @spec allow!(Plug.Conn.t() | User.t(), permission_path :: String.t()) :: no_return | :ok
  def allow!(%Plug.Conn{} = conn, permission_path) when is_binary(permission_path),
    do: allow!(conn, permission_path, nil)

  def allow!(%User{} = user, permission_path) when is_binary(permission_path),
    do: allow!(%Plug.Conn{private: %{guardian_default_resource: user}}, permission_path, nil)

  @doc """
  Same as `ACL.allow!/2` but allows a custom error message to be raised if the
  `User` does not have the proper permissions.
  """
  @spec allow!(
          %Plug.Conn{} | User.t(),
          permission_path :: String.t(),
          error_msg :: String.t() | nil
        ) :: no_return | :ok
  def allow!(
        %Plug.Conn{private: %{guardian_default_resource: user}} = _conn,
        permission_path,
        error_msg
      )
      when is_binary(permission_path) do
    # check if login is required to view forum
    config = Application.get_env(:epochtalk_server, :frontend_config)
    login_required = config["login_required"]

    # default to user's roles > anonymous > private
    user_roles =
      if user == nil,
        do:
          if(login_required, do: [Role.by_lookup("private")], else: [Role.by_lookup("anonymous")]),
        else: user.roles

    authed_permissions = Role.get_masked_permissions(user_roles)

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
        %Plug.Conn{} = _conn,
        permission_path,
        error_msg
      )
      when is_binary(permission_path) and is_binary(error_msg),
      do:
        allow!(
          %Plug.Conn{private: %{guardian_default_resource: nil}},
          permission_path,
          error_msg
        )

  def allow!(
        %User{} = user,
        permission_path,
        error_msg
      )
      when is_binary(permission_path) and is_binary(error_msg),
      do:
        allow!(
          %Plug.Conn{private: %{guardian_default_resource: user}},
          permission_path,
          error_msg
        )
end
