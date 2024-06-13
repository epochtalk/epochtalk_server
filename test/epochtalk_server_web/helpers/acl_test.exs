defmodule Test.EpochtalkServerWeb.Helpers.ACL do
  @moduledoc """
  This test sets async: false because it changes Application env,
  which can cause config issues in other tests
  """
  use Test.Support.ConnCase, async: false
  alias EpochtalkServerWeb.Helpers.ACL
  alias EpochtalkServerWeb.CustomErrors.InvalidPermission

  describe "allow!/2" do
    @tag :authenticated
    test "when authenticated with valid 'User' role permissions, returns :ok", %{authed_user: authed_user} do
      assert ACL.allow!(authed_user, "boards.allCategories") == :ok
      assert ACL.allow!(authed_user, "posts.create") == :ok
      assert ACL.allow!(authed_user, "threads.create") == :ok
      assert ACL.allow!(authed_user, "boards.allCategories.allow") == :ok
      assert ACL.allow!(authed_user, "posts.create.allow") == :ok
      assert ACL.allow!(authed_user, "threads.create.allow") == :ok
    end

    test "when not authenticated, defaults to 'anonymous' role" do
      assert ACL.allow!(%Plug.Conn{}, "boards.allCategories") == :ok
      assert ACL.allow!(%Plug.Conn{}, "posts.byThread") == :ok

      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     ACL.allow!(%Plug.Conn{}, "posts.create")
                   end
    end

    test "when login is required, defaults to 'private' role", %{conn: conn} do
      #TODO(boka): use frontend config updater when implemented
      # set login_required to true in frontend config
      original_frontend_config = Application.get_env(:epochtalk_server, :frontend_config)
      updated_frontend_config =
        original_frontend_config
        |> Map.put(:login_required, true)

      Application.put_env(:epochtalk_server, :frontend_config, updated_frontend_config)

      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     ACL.allow!(conn, "boards.allCategories")
                   end

      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     ACL.allow!(conn, "posts.create")
                   end

      # reset frontend config
      Application.put_env(:epochtalk_server, :frontend_config, original_frontend_config)
    end

    test "when unauthenticated, raises 'InvalidPermissions' error" do
      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     ACL.allow!(%Plug.Conn{}, "posts.create")
                   end

      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     ACL.allow!(%Plug.Conn{}, "threads.create")
                   end
    end

    @tag :authenticated
    test "when authenticated with invalid 'User' role permissions, raises 'InvalidPermissions' error", %{
      authed_user: authed_user
    } do
      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     ACL.allow!(authed_user, "roles.update")
                   end

      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     ACL.allow!(authed_user, "roles.create")
                   end

      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     ACL.allow!(authed_user, "adminSettings.find")
                   end
    end
  end

  describe "allow!/3" do
    @tag :authenticated
    test "when authenticated with valid 'User' role permissions, returns :ok", %{authed_user: authed_user} do
      assert ACL.allow!(authed_user, "boards.allCategories", "You cannot query all categories") ==
               :ok

      assert ACL.allow!(authed_user, "posts.create", "You cannot create posts") == :ok
      assert ACL.allow!(authed_user, "threads.create", "You cannot create threads") == :ok

      assert ACL.allow!(
               authed_user,
               "boards.allCategories.allow",
               "You cannot query all categories"
             ) ==
               :ok

      assert ACL.allow!(authed_user, "posts.create.allow", "You cannot create posts") == :ok
      assert ACL.allow!(authed_user, "threads.create.allow", "You cannot create threads") == :ok
    end

    test "when unauthenticated, raises 'InvalidPermissions' error" do
      assert_raise InvalidPermission, ~r/^You cannot create posts/, fn ->
        ACL.allow!(%Plug.Conn{}, "posts.create", "You cannot create posts")
      end

      assert_raise InvalidPermission, ~r/^You cannot create threads/, fn ->
        ACL.allow!(%Plug.Conn{}, "threads.create", "You cannot create threads")
      end
    end

    test "when unauthenticated, defaults to 'anonymous' role" do
      assert ACL.allow!(%Plug.Conn{}, "boards.allCategories", "You cannot query all categories") ==
               :ok

      assert ACL.allow!(%Plug.Conn{}, "posts.byThread", "You cannot query threads") == :ok

      assert_raise InvalidPermission,
                   ~r/^You cannot create posts/,
                   fn ->
                     ACL.allow!(%Plug.Conn{}, "posts.create", "You cannot create posts")
                   end
    end

    test "when login is required, defaults to 'private' role", %{conn: conn} do
      #TODO(boka): use frontend config updater when implemented
      # set login_required to true in frontend config
      original_frontend_config = Application.get_env(:epochtalk_server, :frontend_config)
      updated_frontend_config =
        original_frontend_config
        |> Map.put(:login_required, true)

      Application.put_env(:epochtalk_server, :frontend_config, updated_frontend_config)

      assert_raise InvalidPermission,
                   ~r/^You cannot view categories/,
                   fn ->
                     ACL.allow!(conn, "boards.allCategories", "You cannot view categories")
                   end

      assert_raise InvalidPermission,
                   ~r/^You cannot create posts/,
                   fn ->
                     ACL.allow!(conn, "posts.create", "You cannot create posts")
                   end

      # reset frontend config
      Application.put_env(:epochtalk_server, :frontend_config, original_frontend_config)
    end

    @tag :authenticated
    test "when authenticated with invalid 'User' role permissions, raises 'InvalidPermissions' error with custom message", %{authed_user: authed_user} do
      assert_raise InvalidPermission, ~r/^You cannot update roles/, fn ->
        ACL.allow!(authed_user, "roles.update", "You cannot update roles")
      end

      assert_raise InvalidPermission, ~r/^You cannot create roles/, fn ->
        ACL.allow!(authed_user, "roles.create", "You cannot create roles")
      end

      assert_raise InvalidPermission, ~r/^You cannot fetch admin settings/, fn ->
        ACL.allow!(authed_user, "adminSettings.find", "You cannot fetch admin settings")
      end
    end
  end

  describe "has_permission/2" do
    @tag :authenticated
    test "when authenticated with valid 'User' role permissions, returns true", %{authed_user: authed_user} do
      assert ACL.has_permission(authed_user, "boards.allCategories") == true
      assert ACL.has_permission(authed_user, "posts.create") == true
      assert ACL.has_permission(authed_user, "threads.create") == true
      assert ACL.has_permission(authed_user, "boards.allCategories.allow") == true
      assert ACL.has_permission(authed_user, "posts.create.allow") == true
      assert ACL.has_permission(authed_user, "threads.create.allow") == true
    end

    test "when unauthenticated, defaults to 'anonymous' role" do
      assert ACL.has_permission(
               %Plug.Conn{private: %{guardian_default_resource: nil}},
               "boards.allCategories"
             ) == true

      assert ACL.has_permission(
               %Plug.Conn{private: %{guardian_default_resource: nil}},
               "posts.byThread"
             ) == true

      assert ACL.has_permission(
               %Plug.Conn{private: %{guardian_default_resource: nil}},
               "posts.create"
             ) == false
    end

    test "when login is required, defaults to 'private' role", %{conn: conn} do
      #TODO(boka): use frontend config updater when implemented
      # set login_required to true in frontend config
      original_frontend_config = Application.get_env(:epochtalk_server, :frontend_config)
      updated_frontend_config =
        original_frontend_config
        |> Map.put(:login_required, true)

      Application.put_env(:epochtalk_server, :frontend_config, updated_frontend_config)

      assert ACL.has_permission(conn, "boards.allCategories") == false
      assert ACL.has_permission(conn, "posts.create") == false

      # reset frontend config
      Application.put_env(:epochtalk_server, :frontend_config, original_frontend_config)
    end

    test "when unauthenticated, returns false" do
      assert ACL.has_permission(
               %Plug.Conn{private: %{guardian_default_resource: nil}},
               "posts.create"
             ) == false

      assert ACL.has_permission(
               %Plug.Conn{private: %{guardian_default_resource: nil}},
               "threads.create"
             ) == false
    end

    @tag :authenticated
    test "when authenticated with invalid 'User' role permissions, returns false", %{
      authed_user: authed_user
    } do
      assert ACL.has_permission(authed_user, "roles.update") == false
      assert ACL.has_permission(authed_user, "roles.create") == false
      assert ACL.has_permission(authed_user, "adminSettings.find") == false
    end
  end
end
