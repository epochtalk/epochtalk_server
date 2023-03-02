defmodule EpochtalkServerWeb.ACLTest do
  use EpochtalkServerWeb.ConnCase, async: true
  alias EpochtalkServerWeb.Helpers.ACL
  alias EpochtalkServerWeb.CustomErrors.InvalidPermission

  describe "allow!/2" do
    @tag :authenticated
    test "returns :ok with valid 'User' role permissions", %{authed_user: authed_user} do
      assert ACL.allow!(authed_user, "boards.allCategories") == :ok
      assert ACL.allow!(authed_user, "posts.create") == :ok
      assert ACL.allow!(authed_user, "threads.create") == :ok
      assert ACL.allow!(authed_user, "boards.allCategories.allow") == :ok
      assert ACL.allow!(authed_user, "posts.create.allow") == :ok
      assert ACL.allow!(authed_user, "threads.create.allow") == :ok
    end

    test "defaults to 'anonymous' role if not authenticated" do
      assert ACL.allow!(%Plug.Conn{}, "boards.allCategories") == :ok
      assert ACL.allow!(%Plug.Conn{}, "posts.byThread") == :ok

      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     ACL.allow!(%Plug.Conn{}, "posts.create")
                   end
    end

    test "defaults to 'private' role if 'frontend_config.login_required' is true", %{conn: conn} do
      frontend_config =
        Application.get_env(:epochtalk_server, :frontend_config)
        |> Map.put(:login_required, true)

      Application.put_env(:epochtalk_server, :frontend_config, frontend_config)

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

      frontend_config =
        Application.get_env(:epochtalk_server, :frontend_config)
        |> Map.put(:login_required, false)

      Application.put_env(:epochtalk_server, :frontend_config, frontend_config)
    end

    test "raises 'InvalidPermissions' error with unauthenticated connection" do
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
    test "raises 'InvalidPermissions' error with invalid 'User' role permissions", %{
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
    test "returns :ok with valid 'User' role permissions", %{authed_user: authed_user} do
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

    test "raises 'InvalidPermissions' error with unauthenticated connection" do
      assert_raise InvalidPermission, ~r/^You cannot create posts/, fn ->
        ACL.allow!(%Plug.Conn{}, "posts.create", "You cannot create posts")
      end

      assert_raise InvalidPermission, ~r/^You cannot create threads/, fn ->
        ACL.allow!(%Plug.Conn{}, "threads.create", "You cannot create threads")
      end
    end

    test "defaults to 'anonymous' role if not authenticated" do
      assert ACL.allow!(%Plug.Conn{}, "boards.allCategories", "You cannot query all categories") ==
               :ok

      assert ACL.allow!(%Plug.Conn{}, "posts.byThread", "You cannot query threads") == :ok

      assert_raise InvalidPermission,
                   ~r/^You cannot create posts/,
                   fn ->
                     ACL.allow!(%Plug.Conn{}, "posts.create", "You cannot create posts")
                   end
    end

    test "defaults to 'private' role if 'frontend_config.login_required' is true", %{conn: conn} do
      frontend_config =
        Application.get_env(:epochtalk_server, :frontend_config)
        |> Map.put(:login_required, true)

      Application.put_env(:epochtalk_server, :frontend_config, frontend_config)

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

      frontend_config =
        Application.get_env(:epochtalk_server, :frontend_config)
        |> Map.put(:login_required, false)

      Application.put_env(:epochtalk_server, :frontend_config, frontend_config)
    end

    @tag :authenticated
    test "raises 'InvalidPermissions' error with custom message with invalid 'User' role permissions",
         %{authed_user: authed_user} do
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
end
