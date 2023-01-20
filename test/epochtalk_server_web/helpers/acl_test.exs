defmodule EpochtalkServerWeb.ACLTest do
  use EpochtalkServerWeb.ConnCase, async: true
  alias EpochtalkServerWeb.Helpers.ACL
  alias EpochtalkServerWeb.CustomErrors.InvalidPermission

  describe "allow!/2" do
    @tag :authenticated
    test "returns :ok with valid 'User' role permissions", %{user: user} do
      assert ACL.allow!(user, "boards.allCategories") == :ok
      assert ACL.allow!(user, "posts.create") == :ok
      assert ACL.allow!(user, "threads.create") == :ok
      assert ACL.allow!(user, "boards.allCategories.allow") == :ok
      assert ACL.allow!(user, "posts.create.allow") == :ok
      assert ACL.allow!(user, "threads.create.allow") == :ok
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
    test "raises 'InvalidPermissions' error with invalid 'User' role permissions", %{user: user} do
      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     ACL.allow!(user, "roles.update")
                   end

      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     ACL.allow!(user, "roles.create")
                   end

      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     ACL.allow!(user, "adminSettings.find")
                   end
    end
  end

  describe "allow!/3" do
    @tag :authenticated
    test "returns :ok with valid 'User' role permissions", %{user: user} do
      assert ACL.allow!(user, "boards.allCategories", "You cannot query all categories") == :ok
      assert ACL.allow!(user, "posts.create", "You cannot create posts") == :ok
      assert ACL.allow!(user, "threads.create", "You cannot create threads") == :ok

      assert ACL.allow!(user, "boards.allCategories.allow", "You cannot query all categories") ==
               :ok

      assert ACL.allow!(user, "posts.create.allow", "You cannot create posts") == :ok
      assert ACL.allow!(user, "threads.create.allow", "You cannot create threads") == :ok
    end

    test "raises 'InvalidPermissions' error with unauthenticated connection" do
      assert_raise InvalidPermission, ~r/^You cannot create posts/, fn ->
        ACL.allow!(%Plug.Conn{}, "posts.create", "You cannot create posts")
      end

      assert_raise InvalidPermission, ~r/^You cannot create threads/, fn ->
        ACL.allow!(%Plug.Conn{}, "threads.create", "You cannot create threads")
      end
    end

    @tag :authenticated
    test "raises 'InvalidPermissions' error with custom message with invalid 'User' role permissions",
         %{user: user} do
      assert_raise InvalidPermission, ~r/^You cannot update roles/, fn ->
        ACL.allow!(user, "roles.update", "You cannot update roles")
      end

      assert_raise InvalidPermission, ~r/^You cannot create roles/, fn ->
        ACL.allow!(user, "roles.create", "You cannot create roles")
      end

      assert_raise InvalidPermission, ~r/^You cannot fetch admin settings/, fn ->
        ACL.allow!(user, "adminSettings.find", "You cannot fetch admin settings")
      end
    end
  end
end
