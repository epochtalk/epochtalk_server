defmodule EpochtalkServerWeb.RoleControllerTest do
  use EpochtalkServerWeb.ConnCase, async: false
  alias EpochtalkServerWeb.CustomErrors.InvalidPermission

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

  describe "update/2" do
    test "errors with unauthorized when not logged", %{conn: conn} do
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

      update_conn = put(conn, Routes.role_path(conn, :update), new_newbie_permissions_attrs)

      assert %{"error" => "Unauthorized", "message" => "No resource found", "status" => 401} == json_response(update_conn, 401)
    end

    @tag :authenticated
    test "errors with unauthorized when logged in but without correct ACL", %{conn: conn} do
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

    @tag authenticated: :admin
    test "modifies a role's priority_restrictions when authenticated", %{conn: conn} do
      initial_newbie_priority_restrictions = nil

      all_conn = get(conn, Routes.role_path(conn, :all))
      roles = json_response(all_conn, 200)

      newbie = roles |> Enum.at(6)
      assert initial_newbie_priority_restrictions == newbie["priority_restrictions"]

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

      update_conn = put(conn, Routes.role_path(conn, :update), new_newbie_permissions_attrs)

      assert "success" == json_response(update_conn, 200)

      modified_all_conn = get(conn, Routes.role_path(conn, :all))
      modified_roles = json_response(modified_all_conn, 200)

      modified_newbie = modified_roles |> Enum.at(6)
      assert modified_newbie_priority_restrictions == modified_newbie["priority_restrictions"]

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

      update_conn = put(conn, Routes.role_path(conn, :update), new_newbie_permissions_attrs)

      assert "success" == json_response(update_conn, 200)

      modified_all_conn = get(conn, Routes.role_path(conn, :all))
      modified_roles = json_response(modified_all_conn, 200)

      modified_newbie = modified_roles |> Enum.at(6)
      assert nil == modified_newbie["priority_restrictions"]
    end

    @tag authenticated: :admin
    test "modifies a role's permissions when authenticated", %{conn: conn} do
      initial_newbie_permissions = %{
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

      all_conn = get(conn, Routes.role_path(conn, :all))
      roles = json_response(all_conn, 200)

      newbie = roles |> Enum.at(6)
      assert initial_newbie_permissions == newbie["permissions"]

      update_conn = put(conn, Routes.role_path(conn, :update), new_newbie_permissions_attrs)
      assert "success" == json_response(update_conn, 200)

      modified_all_conn = get(conn, Routes.role_path(conn, :all))
      modified_roles = json_response(modified_all_conn, 200)
      modified_newbie = modified_roles |> Enum.at(6)
      assert modified_newbie_permissions == modified_newbie["permissions"]
    end
  end
end
