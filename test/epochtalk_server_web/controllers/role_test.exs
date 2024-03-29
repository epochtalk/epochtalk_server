defmodule Test.EpochtalkServerWeb.Controllers.Role do
  @moduledoc """
  This test sets async: false because it uses the RoleCache, which will run into
  concurrency issues when run alongside other tests
  """
  use Test.Support.ConnCase, async: false
  alias EpochtalkServerWeb.CustomErrors.InvalidPermission
  alias EpochtalkServer.Cache.Role, as: RoleCache
  @postgres_integer_max 2_147_483_647
  @postgres_varchar255_max 255
  @description_max 1000

  describe "all/2" do
    @tag :authenticated
    test "when authenticated, gets all roles", %{conn: conn} do
      RoleCache.reload()
      conn = get(conn, Routes.role_path(conn, :all))
      roles = json_response(conn, 200)

      newbie_permissions = %{
        "ads" => %{
          "analyticsView" => %{"allow" => true},
          "roundInfo" => %{"allow" => true},
          "view" => %{"allow" => true}
        },
        "boards" => %{
          "allCategories" => %{"allow" => true},
          "find" => %{"allow" => true}
        },
        "conversations" => %{
          "create" => %{"allow" => true},
          "delete" => %{"allow" => true},
          "messages" => %{"allow" => true}
        },
        "mentions" => %{
          "create" => %{"allow" => true},
          "delete" => %{"allow" => true},
          "page" => %{"allow" => true}
        },
        "messages" => %{
          "create" => %{"allow" => true},
          "delete" => %{"allow" => true, "bypass" => %{"owner" => true}},
          "latest" => %{"allow" => true}
        },
        "motd" => %{"get" => %{"allow" => true}},
        "notifications" => %{
          "counts" => %{"allow" => true},
          "dismiss" => %{"allow" => true}
        },
        "portal" => %{"view" => %{"allow" => true}},
        "posts" => %{
          "byThread" => %{"allow" => true},
          "create" => %{"allow" => true},
          "delete" => %{"allow" => true},
          "find" => %{"allow" => true},
          "pageByUser" => %{"allow" => true},
          "search" => %{"allow" => true},
          "update" => %{"allow" => true}
        },
        "reports" => %{
          "createMessageReport" => %{"allow" => true},
          "createPostReport" => %{"allow" => true},
          "createUserReport" => %{"allow" => true}
        },
        "threads" => %{
          "byBoard" => %{"allow" => true},
          "create" => %{"allow" => true},
          "createPoll" => %{"allow" => true},
          "editPoll" => %{"allow" => true},
          "lockPoll" => %{"allow" => true},
          "posted" => %{"allow" => true},
          "removeVote" => %{"allow" => true},
          "title" => %{"allow" => true},
          "viewed" => %{"allow" => true},
          "vote" => %{"allow" => true}
        },
        "userTrust" => %{"addTrustFeedback" => %{"allow" => true}},
        "users" => %{
          "deactivate" => %{"allow" => true},
          "find" => %{"allow" => true},
          "lookup" => %{"allow" => true},
          "pagePublic" => %{"allow" => true},
          "reactivate" => %{"allow" => true},
          "update" => %{"allow" => true}
        },
        "watchlist" => %{
          "edit" => %{"allow" => true},
          "pageBoards" => %{"allow" => true},
          "pageThreads" => %{"allow" => true},
          "unread" => %{"allow" => true},
          "unwatchBoard" => %{"allow" => true},
          "unwatchThread" => %{"allow" => true},
          "watchBoard" => %{"allow" => true},
          "watchThread" => %{"allow" => true}
        }
      }

      initial_newbie_priority_restrictions = nil

      newbie_role = roles |> Enum.at(6)
      assert newbie_role["permissions"] == newbie_permissions
      assert newbie_role["priority_restrictions"] == initial_newbie_priority_restrictions

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

    test "when not authenticated, does not get roles", %{conn: conn} do
      response =
        conn
        |> get(Routes.role_path(conn, :all))
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
    end
  end

  describe "update/2" do
    test "when not logged in, errors with unauthorized", %{conn: conn} do
      modified_newbie_priority_restrictions = [1, 2, 3]

      new_newbie_permissions_attrs = %{
        id: 7,
        permissions: %{
          adminAccess: %{
            management: %{
              bannedAddresses: true
            }
          }
        },
        priority_restrictions: modified_newbie_priority_restrictions
      }

      response =
        conn
        |> put(Routes.role_path(conn, :update), new_newbie_permissions_attrs)
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
    end

    @tag :authenticated
    test "when logged in and given incorrect ACL, errors with unauthorized", %{conn: conn} do
      modified_newbie_priority_restrictions = [1, 2, 3]

      new_newbie_permissions_attrs = %{
        id: 7,
        permissions: %{
          adminAccess: %{
            management: %{
              bannedAddresses: true
            }
          }
        },
        priority_restrictions: modified_newbie_priority_restrictions
      }

      assert_raise InvalidPermission,
                   ~r/^Forbidden, invalid permissions to perform this action/,
                   fn ->
                     put(conn, Routes.role_path(conn, :update), new_newbie_permissions_attrs)
                   end
    end

    @tag authenticated: :super_admin
    test "given properties, modifies a role", %{conn: conn} do
      RoleCache.reload()

      new_newbie_permissions_attrs = %{
        id: 7,
        name: "Changed Name",
        description: "Changed Description",
        priority: 100,
        lookup: "Changed Lookup",
        highlight_color: "#00Ff00"
      }

      update_response =
        conn
        |> put(Routes.role_path(conn, :update), new_newbie_permissions_attrs)
        |> json_response(200)

      assert update_response == new_newbie_permissions_attrs.id

      modified_newbie =
        conn
        |> get(Routes.role_path(conn, :all))
        |> json_response(200)
        |> Enum.at(6)

      assert modified_newbie["name"] == new_newbie_permissions_attrs.name
      assert modified_newbie["description"] == new_newbie_permissions_attrs.description
      assert modified_newbie["priority"] == new_newbie_permissions_attrs.priority
      assert modified_newbie["lookup"] == new_newbie_permissions_attrs.lookup
      assert modified_newbie["highlight_color"] == new_newbie_permissions_attrs.highlight_color

      blank_hc_attrs = %{id: 7, highlight_color: ""}

      blank_hc_response =
        conn
        |> put(Routes.role_path(conn, :update), blank_hc_attrs)
        |> json_response(200)

      assert blank_hc_response == blank_hc_attrs.id

      blank_hc_newbie =
        conn
        |> get(Routes.role_path(conn, :all))
        |> json_response(200)
        |> Enum.at(6)

      assert blank_hc_newbie["highlight_color"] == nil
    end

    @tag authenticated: :super_admin
    test "given no properties, does not modify a role", %{conn: conn} do
      RoleCache.reload()
      new_newbie_permissions_attrs = %{id: 7}

      original_newbie =
        conn
        |> get(Routes.role_path(conn, :all))
        |> json_response(200)
        |> Enum.at(6)

      update_response =
        conn
        |> put(Routes.role_path(conn, :update), new_newbie_permissions_attrs)
        |> json_response(200)

      assert update_response == new_newbie_permissions_attrs.id

      modified_newbie =
        conn
        |> get(Routes.role_path(conn, :all))
        |> json_response(200)
        |> Enum.at(6)

      assert modified_newbie["name"] == original_newbie["name"]
      assert modified_newbie["description"] == original_newbie["description"]
      assert modified_newbie["priority"] == original_newbie["priority"]
      assert modified_newbie["lookup"] == original_newbie["lookup"]
      assert modified_newbie["highlight_color"] == original_newbie["highlight_color"]
    end

    @tag authenticated: :super_admin
    test "when fields are not properly formatted, errors", %{conn: conn} do
      original_newbie =
        conn
        |> get(Routes.role_path(conn, :all))
        |> json_response(200)
        |> Enum.at(6)

      short_name_attrs = %{id: 7, name: ""}
      long_name_attrs = %{id: 7, name: String.duplicate("a", @postgres_varchar255_max + 1)}
      short_lu_attrs = %{id: 7, lookup: ""}
      long_lu_attrs = %{id: 7, lookup: String.duplicate("a", @postgres_varchar255_max + 1)}
      uniq_lu_attrs = %{id: 7, lookup: "superAdministrator"}
      short_desc_attrs = %{id: 7, description: ""}
      long_desc_attrs = %{id: 7, description: String.duplicate("a", @description_max + 1)}
      low_prio_attrs = %{id: 7, priority: -1}
      high_prio_attrs = %{id: 7, priority: @postgres_integer_max + 1}
      bad_hc_attrs = %{id: 7, highlight_color: "lol"}

      short_name_response =
        conn
        |> put(Routes.role_path(conn, :update), short_name_attrs)
        |> json_response(400)

      long_name_response =
        conn
        |> put(Routes.role_path(conn, :update), long_name_attrs)
        |> json_response(400)

      short_lu_response =
        conn
        |> put(Routes.role_path(conn, :update), short_lu_attrs)
        |> json_response(400)

      long_lu_response =
        conn
        |> put(Routes.role_path(conn, :update), long_lu_attrs)
        |> json_response(400)

      uniq_lu_response =
        conn
        |> put(Routes.role_path(conn, :update), uniq_lu_attrs)
        |> json_response(400)

      short_desc_response =
        conn
        |> put(Routes.role_path(conn, :update), short_desc_attrs)
        |> json_response(400)

      long_desc_response =
        conn
        |> put(Routes.role_path(conn, :update), long_desc_attrs)
        |> json_response(400)

      low_prio_response =
        conn
        |> put(Routes.role_path(conn, :update), low_prio_attrs)
        |> json_response(400)

      high_prio_response =
        conn
        |> put(Routes.role_path(conn, :update), high_prio_attrs)
        |> json_response(400)

      bad_hc_response =
        conn
        |> put(Routes.role_path(conn, :update), bad_hc_attrs)
        |> json_response(400)

      assert short_name_response["message"] == "Name can't be blank"
      assert long_name_response["message"] == "Name should be at most 255 character(s)"
      assert short_lu_response["message"] == "Lookup can't be blank"
      assert long_lu_response["message"] == "Lookup should be at most 255 character(s)"
      assert uniq_lu_response["message"] == "Lookup has already been taken"
      assert short_desc_response["message"] == "Description can't be blank"
      assert long_desc_response["message"] == "Description should be at most 1000 character(s)"
      assert low_prio_response["message"] == "Priority must be greater than or equal to 1"
      assert high_prio_response["message"] == "Priority must be less than or equal to 2147483647"
      assert bad_hc_response["message"] == "Highlight_color has invalid format"

      modified_newbie =
        conn
        |> get(Routes.role_path(conn, :all))
        |> json_response(200)
        |> Enum.at(6)

      assert modified_newbie["name"] == original_newbie["name"]
      assert modified_newbie["description"] == original_newbie["description"]
      assert modified_newbie["priority"] == original_newbie["priority"]
      assert modified_newbie["lookup"] == original_newbie["lookup"]
    end

    @tag authenticated: :super_admin
    test "when authenticated, modifies a role's priority_restrictions", %{conn: conn} do
      RoleCache.reload()
      initial_newbie_priority_restrictions = nil

      newbie =
        conn
        |> get(Routes.role_path(conn, :all))
        |> json_response(200)
        |> Enum.at(6)

      assert newbie["priority_restrictions"] == initial_newbie_priority_restrictions

      modified_newbie_priority_restrictions = [1, 2, 3]

      new_newbie_permissions_attrs = %{
        id: 7,
        permissions: %{
          adminAccess: %{
            management: %{
              bannedAddresses: true
            }
          }
        },
        priority_restrictions: modified_newbie_priority_restrictions
      }

      update_response =
        conn
        |> put(Routes.role_path(conn, :update), new_newbie_permissions_attrs)
        |> json_response(200)

      assert update_response == new_newbie_permissions_attrs.id

      modified_newbie =
        conn
        |> get(Routes.role_path(conn, :all))
        |> json_response(200)
        |> Enum.at(6)

      assert modified_newbie["priority_restrictions"] == modified_newbie_priority_restrictions

      re_modified_newbie_priority_restrictions = []

      new_newbie_permissions_attrs = %{
        id: 7,
        permissions: %{
          adminAccess: %{
            management: %{
              bannedAddresses: true
            }
          }
        },
        priority_restrictions: re_modified_newbie_priority_restrictions
      }

      new_update_response =
        conn
        |> put(Routes.role_path(conn, :update), new_newbie_permissions_attrs)
        |> json_response(200)

      assert new_update_response == new_newbie_permissions_attrs.id

      modified_newbie =
        conn
        |> get(Routes.role_path(conn, :all))
        |> json_response(200)
        |> Enum.at(6)

      assert modified_newbie["priority_restrictions"] == nil
    end

    @tag authenticated: :super_admin
    test "when input is invalid, does not modify a role's priority_restrictions", %{conn: conn} do
      RoleCache.reload()

      initial_newbie_priority_restrictions =
        get(conn, Routes.role_path(conn, :all))
        |> json_response(200)
        |> Enum.at(6)
        |> Map.get("priority_restrictions")

      invalid_modified_newbie_priority_restrictions = ""

      new_newbie_permissions_attrs = %{
        id: 7,
        priority_restrictions: invalid_modified_newbie_priority_restrictions
      }

      update_response =
        conn
        |> put(Routes.role_path(conn, :update), new_newbie_permissions_attrs)
        |> json_response(200)

      assert update_response == new_newbie_permissions_attrs.id

      modified_newbie =
        conn
        |> get(Routes.role_path(conn, :all))
        |> json_response(200)
        |> Enum.at(6)

      assert modified_newbie["priority_restrictions"] !=
               invalid_modified_newbie_priority_restrictions

      assert modified_newbie["priority_restrictions"] == initial_newbie_priority_restrictions
    end

    @tag authenticated: :super_admin
    test "when authenticated, modifies a role's permissions", %{conn: conn} do
      RoleCache.reload()

      new_newbie_permissions_attrs = %{
        id: 7,
        permissions: %{
          adminAccess: %{
            management: %{
              bannedAddresses: true
            }
          }
        },
        priority_restrictions: []
      }

      modified_newbie_permissions = %{
        "adminAccess" => %{
          "management" => %{
            "bannedAddresses" => true
          }
        }
      }

      update_response =
        conn
        |> put(Routes.role_path(conn, :update), new_newbie_permissions_attrs)
        |> json_response(200)

      assert update_response == new_newbie_permissions_attrs.id

      modified_newbie =
        conn
        |> get(Routes.role_path(conn, :all))
        |> json_response(200)
        |> Enum.at(6)

      assert modified_newbie["permissions"] == modified_newbie_permissions
    end

    @tag authenticated: :super_admin
    test "when input is invalid, does not modify a user's permissions", %{conn: conn} do
      RoleCache.reload()

      initial_newbie_permissions =
        conn
        |> get(Routes.role_path(conn, :all))
        |> json_response(200)
        |> Enum.at(6)
        |> Map.get("permissions")

      invalid_modified_newbie_permissions = ""

      new_newbie_permissions_attrs = %{
        id: 7,
        permissions: invalid_modified_newbie_permissions
      }

      update_response =
        conn
        |> put(Routes.role_path(conn, :update), new_newbie_permissions_attrs)
        |> json_response(200)

      assert update_response == new_newbie_permissions_attrs.id

      modified_newbie =
        conn
        |> get(Routes.role_path(conn, :all))
        |> json_response(200)
        |> Enum.at(6)

      assert modified_newbie["permissions"] != invalid_modified_newbie_permissions
      assert modified_newbie["permissions"] == initial_newbie_permissions
    end
  end
end
