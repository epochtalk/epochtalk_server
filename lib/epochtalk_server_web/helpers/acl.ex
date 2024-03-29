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

  def allow!(%{} = user, permission_path) when is_binary(permission_path),
    do: allow!(%Plug.Conn{private: %{guardian_default_resource: user}}, permission_path, nil)

  @doc """
  Same as `ACL.allow!/2` but allows a custom error message to be raised if the
  `User` does not have the proper permissions.
  """
  @spec allow!(
          Plug.Conn.t() | User.t() | any(),
          permission_path :: String.t(),
          error_msg :: String.t() | nil
        ) :: no_return | :ok
  def allow!(
        %Plug.Conn{private: %{guardian_default_resource: _user}} = conn,
        permission_path,
        error_msg
      )
      when is_binary(permission_path) do
    has_permission = has_permission(conn, permission_path)
    if !has_permission, do: raise(InvalidPermission, message: error_msg)
    :ok
  end

  def allow!(
        %User{} = user,
        permission_path,
        error_msg
      )
      when (is_binary(permission_path) and is_binary(error_msg)) or is_nil(error_msg),
      do:
        allow!(
          %Plug.Conn{private: %{guardian_default_resource: user}},
          permission_path,
          error_msg
        )

  def allow!(
        _,
        permission_path,
        error_msg
      )
      when (is_binary(permission_path) and is_binary(error_msg)) or is_nil(error_msg),
      do:
        allow!(
          %Plug.Conn{private: %{guardian_default_resource: nil}},
          permission_path,
          error_msg
        )

  @doc """
  Returns boolean indicating if supplied `User` or authenticated `Plug.Conn.t()` has the
  a role with the supplied `Permission` path.
  """
  @spec has_permission(
          Plug.Conn.t() | User.t() | any(),
          permission_path :: String.t()
        ) :: boolean
  def has_permission(
        %Plug.Conn{private: %{guardian_default_resource: user}} = _conn,
        permission_path
      )
      when is_binary(permission_path) do
    # check if login is required to view forum
    config = Application.get_env(:epochtalk_server, :frontend_config)
    login_required = config[:login_required] || config["login_required"]
    # default to user's roles > anonymous > private
    user_roles =
      if user == nil,
        do:
          if(login_required,
            do: [Role.by_lookup("private")],
            else: [Role.by_lookup("anonymous")]
          ),
        else: user.roles

    authed_permissions = Role.get_masked_permissions(user_roles)

    # convert path to array
    path_list = String.split(permission_path, ".")

    # check provided permission path
    has_permission = Kernel.get_in(authed_permissions, path_list)

    # if has_permission is nil, append "allow" to provided permission
    # path and try again
    has_permission =
      if is_nil(has_permission) and List.last(path_list) != "allow",
        do: Kernel.get_in(authed_permissions, path_list ++ ["allow"]),
        else: has_permission

    # converts output to boolean, nil -> false, true -> true
    !!has_permission
  end

  def has_permission(%Plug.Conn{}, permission_path) when is_binary(permission_path),
    do: has_permission(%Plug.Conn{private: %{guardian_default_resource: nil}}, permission_path)

  def has_permission(%User{} = user, permission_path) when is_binary(permission_path),
    do: has_permission(%Plug.Conn{private: %{guardian_default_resource: user}}, permission_path)

  def has_permission(%{} = user, permission_path) when is_binary(permission_path),
    do: has_permission(%Plug.Conn{private: %{guardian_default_resource: user}}, permission_path)

  def has_permission(nil, permission_path) when is_binary(permission_path),
    do: has_permission(%Plug.Conn{private: %{guardian_default_resource: nil}}, permission_path)

  @doc """
  Helper which returns the active User's priority.

  Will return priorty of role with highest permissions if the user is authenticated, otherwise anonymous priority
  is returned if `frontend_config.login_required` is false otherwise private role priority is returned. If
  user is banned the Banned role priority is returned.
  """
  # TODO(akinsey): review chain of authenticated user's roles. See if banned and user roles are being defaulted
  # prior to calling this function or if this function should handle defaulting the user's roles
  @spec get_user_priority(Plug.Conn.t() | User.t()) :: non_neg_integer
  def get_user_priority(%{id: id, roles: roles} = _user) when not is_nil(id) and is_list(roles),
    do: Role.get_masked_permissions(roles).priority

  def get_user_priority(%Plug.Conn{private: %{guardian_default_resource: user}} = _conn)
      when not is_nil(user.id) and is_list(user.roles),
      do: Role.get_masked_permissions(user.roles).priority

  def get_user_priority(%Plug.Conn{} = _conn),
    do: Role.get_default_unauthenticated().priority

  def get_user_priority(nil),
    do: Role.get_default_unauthenticated().priority

  @doc """
  Returns boolean indicating if supplied `User` has the role with the supplied
  `lookup` path.
  """
  @spec has_role(
          user :: User.t() | map(),
          role_lookup :: String.t()
        ) :: boolean
  def has_role(%{roles: roles} = _user, role_lookup) do
    if roles == [] and role_lookup == "user",
      do: true,
      else:
        Enum.reduce(roles, false, fn role, has_role ->
          has_role || role.lookup == role_lookup
        end)
  end
end
