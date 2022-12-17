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
