defmodule EpochtalkServerWeb.RoleControllerTest do
  use EpochtalkServerWeb.ConnCase, async: false

  describe "all/2" do
    @tag :authenticated
    test "gets all roles when authenticated", %{conn: conn} do
      conn = get(conn, Routes.role_path(conn, :all))
      roles = json_response(conn, 200)

      assert [
               %{
                 "lookup" => "superAdministrator",
                 "name" => "Super Administrator",
                 "priority" => 0
               }
               | roles
             ] = roles

      assert [%{"lookup" => "administrator", "name" => "Administrator", "priority" => 1} | roles] =
               roles

      assert [
               %{"lookup" => "globalModerator", "name" => "Global Moderator", "priority" => 2}
               | roles
             ] = roles

      assert [%{"lookup" => "moderator", "name" => "Moderator", "priority" => 3} | roles] = roles
      assert [%{"lookup" => "user", "name" => "User", "priority" => 4} | roles] = roles
      assert [%{"lookup" => "patroller", "name" => "Patroller", "priority" => 5} | roles] = roles
      assert [%{"lookup" => "newbie", "name" => "Newbie", "priority" => 6} | roles] = roles
      assert [%{"lookup" => "banned", "name" => "Banned", "priority" => 7} | roles] = roles
      assert [%{"lookup" => "anonymous", "name" => "Anonymous", "priority" => 8} | roles] = roles
      assert [%{"lookup" => "private", "name" => "Private", "priority" => 9} | roles] = roles
      assert [] = roles
    end

    test "does not get roles when not authenticated", %{conn: conn} do
      conn = get(conn, Routes.role_path(conn, :all))

      assert %{"error" => "Unauthorized", "message" => "No resource found"} =
               json_response(conn, 401)
    end
  end
end
