defmodule EpochtalkServerWeb.Helpers.ACL do
  alias EpochtalkServerWeb.Helpers.ACL
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.BoardModerator
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
    login_required = config[:login_required]
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

  Will return priority of role with highest permissions if the user is authenticated, otherwise anonymous priority
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

  @doc """
  Used to check route authorization when modifying a `Post` or related models (e.g. `Thread` or `Poll`).
  This function returns a boolean indicating if the authenticated `User` can bypass the `Post` owner, given
  a `User` map, `Post` map, `Permission` string, `bypass_type` string, a `custom_condition` boolean, and optionally a boolean
  indicating whether or not to compare moderator priorities if both users are moderators and lastly another optional boolean
  to indicating if priority based bypasses should be checked.
  """
  @spec bypass_post_owner(
          user :: map(),
          post :: map(),
          permission :: String.t(),
          bypass_type :: String.t(),
          custom_condition :: boolean,
          check_priority_bypass :: boolean | nil,
          compare_mod_priorities :: boolean | nil
        ) :: boolean
  def bypass_post_owner(
        user,
        post,
        permission,
        bypass_type,
        custom_condition,
        check_priority_bypass \\ false,
        compare_mod_priorities \\ false
      ) do
    # check if user is admin
    has_admin_bypass = ACL.has_permission(user, "#{permission}.bypass.#{bypass_type}.admin")

    # if compare_mod_priorities is true, check that authed moderator has greater priority than
    # the post author moderator
    is_mod_with_higher_priority =
      if compare_mod_priorities,
        do:
          ACL.has_priority_bypass_or_is_owner(
            user,
            "#{permission}.bypass.#{bypass_type}.mod",
            post
          ),
        else: true

    # check user is mod, has mod bypass permission and lastly compare priorities between mods in
    # some cases (e.g. editing another mods post)
    has_mod_bypass =
      BoardModerator.user_is_moderator_with_thread_id(post.thread_id, user.id) and
        ACL.has_permission(user, "#{permission}.bypass.#{bypass_type}.mod") and
        is_mod_with_higher_priority

    # check if user has priority based override (e.g. patroller role)
    has_priority_bypass =
      if check_priority_bypass,
        do:
          ACL.has_priority_bypass_or_is_owner(
            user,
            "#{permission}.bypass.#{bypass_type}.priority",
            post
          ),
        else: false

    has_admin_bypass or custom_condition or has_mod_bypass or has_priority_bypass
  end

  @doc """
  This function returns a boolean indicating if the auth `User` has the permission and priority to
  modify the `Post` given an authed`User`, a `Permission` string, the `Post` attempting to be
  modified and a boolean indicating if self moderation should be taken into consideration, this
  function will return a boolean indicating if the auth `User` has priority to modify the `Post`
  """
  @spec has_priority_bypass_or_is_owner(
          user :: map(),
          permission :: String.t(),
          post :: map(),
          self_mod :: boolean | nil
        ) ::
          boolean
  def has_priority_bypass_or_is_owner(user, permission, post, self_mod \\ false) do
    # check permission
    has_permission = ACL.has_permission(user, permission)

    # check if authed user is post owner
    is_post_owner = post.user_id == user.id

    # user is post owner and has permissions
    valid_post_owner = has_permission and is_post_owner

    # doesn't own post check users permissions
    valid_post_owner_override =
      has_permission and !is_post_owner and has_priority_bypass(user, post, self_mod)

    # if has permission and post owner allow, if has permission and not post owner do additional checks
    valid_post_owner or valid_post_owner_override
  end

  ## === Private Helper Functions ===

  defp has_priority_bypass(user, post, self_mod) do
    post_author_is_mod = BoardModerator.user_is_moderator_with_post_id(post.id, post.user_id)

    post_author_priority = ACL.get_user_priority(post.user)

    # empty roles array means post author is a "user"
    post_author_is_user = post.user.roles == []

    authed_user_priority = ACL.get_user_priority(user)

    # check authed user roles for patroller role
    authed_user_is_patroller = ACL.has_role(user, "patroller")

    # authed user has higher or same priority as post author, self mod is not enabled
    authed_user_has_priority_no_self_mod =
      authed_user_priority <= post_author_priority and !self_mod

    # authed user has higher or same priority as post author, self mod is enabled, post author is not a mod
    authed_user_has_priority_self_mod =
      authed_user_priority <= post_author_priority and self_mod and !post_author_is_mod

    # Allows `patrollers` to have priority over `users` within self moderated threads
    authed_user_has_patroller_permissions =
      self_mod and post_author_is_user and authed_user_is_patroller

    # determine if authed user has priority over post author
    authed_user_has_priority_no_self_mod or authed_user_has_priority_self_mod or
      authed_user_has_patroller_permissions
  end
end
