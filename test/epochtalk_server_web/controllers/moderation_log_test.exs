defmodule Test.EpochtalkServerWeb.Controllers.ModerationLog do
  use Test.Support.ConnCase, async: true
  alias EpochtalkServer.Models.ModerationLog
  import Test.Support.Factory

  @user %{
    username: "user"
  }
  @admin %{
    username: "admin"
  }
  @old_board %{
    name: "Old Board",
    slug: "old-board"
  }
  @super_admin_role %{
    id: 1,
    name: "Super Administrator"
  }
  @thread %{
    title: "Thread",
    slug: "thread-slug"
  }
  @new_thread %{
    title: "New Thread"
  }
  @status "status"
  @message_report_id 10
  @post_report_id 20
  @user_report_id 30
  @ban_expiration "31 Dec 2030"
  @mod_address "127.0.0.2"
  @banned_address "127.0.0.1"
  @weight 99

  @create_update_boards_attrs %{
    mod: %{username: @admin.username, id: 1, ip: @mod_address},
    action: %{
      api_url: "/api/boards/all",
      api_method: "post",
      type: "adminBoards.updateCategories",
      obj: %{}
    }
  }

  # @create_add_moderators_attrs %{
  #   mod: %{username: @admin.username, id: 2, ip: @mod_address},
  #   action: %{
  #     api_url: "/api/admin/moderators",
  #     api_method: "post",
  #     type: "adminModerators.add",
  #     obj: %{
  #       usernames: [@user.username],
  #       board_id: @board.id
  #     }
  #   }
  # }

  defp compare(result_moderation_log, factory_moderation_log) do
    result_moderation_log["action_api_method"] == factory_moderation_log.action_api_method
    &&
    result_moderation_log["action_api_url"] == factory_moderation_log.action_api_url
    &&
    result_moderation_log["action_display_text"] == factory_moderation_log.action_display_text
    &&
    result_moderation_log["action_display_url"] == factory_moderation_log.action_display_url
    &&
    result_moderation_log["action_obj"] == factory_moderation_log.action_obj
    &&
    result_moderation_log["action_taken_at"] |> NaiveDateTime.from_iso8601!() == factory_moderation_log.action_taken_at
    &&
    result_moderation_log["action_type"] == factory_moderation_log.action_type
    &&
    result_moderation_log["mod_id"] == factory_moderation_log.mod_id
    &&
    result_moderation_log["mod_ip"] == factory_moderation_log.mod_ip
    &&
    result_moderation_log["mod_username"] == factory_moderation_log.mod_username
  end

  defp response_for_mod(conn, mod) do
    conn
    |> get(Routes.moderation_log_path(conn, :page, %{"mod" => mod}))
    |> json_response(200)
    |> Map.get("moderation_logs")
    |> List.first()
  end

  describe "page/1" do
    @tag :authenticated
    test "given mod username, when action_type is 'adminBoards.updateCategories', gets page", %{conn: conn} do
      factory_moderation_log = build(:moderation_log, %{
        api_url: "/api/boards/all",
        api_method: "post",
        type: "adminBoards.updateCategories",
        obj: %{}
      })

      response_moderation_log =
        conn |> response_for_mod(factory_moderation_log.mod_username)

      assert compare(response_moderation_log, factory_moderation_log)
    end

    @tag :authenticated
    test "given mod_id, when action_type is 'adminBoards.updateCategories', gets page", %{conn: conn} do
      factory_moderation_log = build(:moderation_log, %{
        api_url: "/api/boards/all",
        api_method: "post",
        type: "adminBoards.updateCategories",
        obj: %{}
      })

      response_moderation_log =
        conn |> response_for_mod(factory_moderation_log.mod_id)

      assert compare(response_moderation_log, factory_moderation_log)
    end

    @tag :authenticated
    test "when action_type is 'adminModerators.add', gets page", %{conn: conn} do
      board = insert(:board)
      factory_moderation_log = build(:moderation_log, %{
        api_url: "/api/admin/moderators",
        api_method: "post",
        type: "adminModerators.add",
        obj: %{usernames: [@user.username], board_id: board.id}
      })

      response_moderation_log =
        conn |> response_for_mod(factory_moderation_log.mod_id)

      assert response_moderation_log == factory_moderation_log
      assert response_moderation_log["action_display_text"] == "added user(s) '#{@user.username}' to list of moderators for board '#{board.name}'"
      assert response_moderation_log["action_display_url"] == "threads.data({ boardSlug: '#{board.slug}' })"
    end

    # @tag :authenticated
    # test "when action_type is 'adminModerators.remove', gets page",
    #      %{conn: conn} do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 6})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 6
    #   assert moderation_log["action_type"] == "adminModerators.remove"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "removed user(s) '#{@user.username}' from list of moderators for board '#{@board.name}'"
    #
    #   assert moderation_log["action_display_url"] ==
    #            "threads.data({ boardSlug: '#{@board.slug}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'reports.updateMessageReport', gets page",
    #      %{conn: conn} do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 7})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 7
    #   assert moderation_log["action_type"] == "reports.updateMessageReport"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "updated the status of message report to '#{@status}'"
    #
    #   assert moderation_log["action_display_url"] == "^.messages({ reportId: '#{@message_report_id}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'reports.createMessageReportNote', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 8})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 8
    #   assert moderation_log["action_type"] == "reports.createMessageReportNote"
    #   assert moderation_log["action_display_text"] == "created a note on a message report"
    #   assert moderation_log["action_display_url"] == "^.messages({ reportId: '#{@message_report_id}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'reports.updateMessageReportNote', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 9})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 9
    #   assert moderation_log["action_type"] == "reports.updateMessageReportNote"
    #   assert moderation_log["action_display_text"] == "edited their note on a message report"
    #   assert moderation_log["action_display_url"] == "^.messages({ reportId: '#{@message_report_id}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'reports.updatePostReport', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 10})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 10
    #   assert moderation_log["action_type"] == "reports.updatePostReport"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "updated the status of post report to '#{@status}'"
    #
    #   assert moderation_log["action_display_url"] == "^.messages({ reportId: '#{@post_report_id}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'reports.createPostReportNote', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 11})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 11
    #   assert moderation_log["action_type"] == "reports.createPostReportNote"
    #   assert moderation_log["action_display_text"] == "created a note on a post report"
    #   assert moderation_log["action_display_url"] == "^.messages({ reportId: '#{@post_report_id}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'reports.updatePostReportNote', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 12})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 12
    #   assert moderation_log["action_type"] == "reports.updatePostReportNote"
    #   assert moderation_log["action_display_text"] == "edited their note on a post report"
    #   assert moderation_log["action_display_url"] == "^.messages({ reportId: '#{@post_report_id}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'reports.updateUserReport', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 13})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 13
    #   assert moderation_log["action_type"] == "reports.updateUserReport"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "updated the status of user report to '#{@status}'"
    #
    #   assert moderation_log["action_display_url"] == "^.messages({ reportId: '#{@user_report_id}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'reports.createUserReportNote', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 14})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 14
    #   assert moderation_log["action_type"] == "reports.createUserReportNote"
    #   assert moderation_log["action_display_text"] == "created a note on a user report"
    #   assert moderation_log["action_display_url"] == "^.messages({ reportId: '#{@user_report_id}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'reports.updateUserReportNote', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 15})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 15
    #   assert moderation_log["action_type"] == "reports.updateUserReportNote"
    #   assert moderation_log["action_display_text"] == "edited their note on a user report"
    #   assert moderation_log["action_display_url"] == "^.messages({ reportId: '#{@user_report_id}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'adminRoles.add', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 16})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 16
    #   assert moderation_log["action_type"] == "adminRoles.add"
    #   assert moderation_log["action_display_text"] == "created a new role named '#{@super_admin_role.name}'"
    #   assert moderation_log["action_display_url"] == "admin-management.roles({ roleId: '#{@super_admin_role.id}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'adminRoles.remove', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 17})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 17
    #   assert moderation_log["action_type"] == "adminRoles.remove"
    #   assert moderation_log["action_display_text"] == "removed the role named '#{@super_admin_role.name}'"
    #   assert moderation_log["action_display_url"] == "admin-management.roles"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'adminRoles.update', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 18})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 18
    #   assert moderation_log["action_type"] == "adminRoles.update"
    #   assert moderation_log["action_display_text"] == "updated the role named '#{@super_admin_role.name}'"
    #   assert moderation_log["action_display_url"] == "admin-management.roles({ roleId: '#{@super_admin_role.id}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'adminRoles.reprioritize', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 19})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 19
    #   assert moderation_log["action_type"] == "adminRoles.reprioritize"
    #   assert moderation_log["action_display_text"] == "reordered role priorities"
    #   assert moderation_log["action_display_url"] == "admin-management.roles"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'adminSettings.update', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 20})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 20
    #   assert moderation_log["action_type"] == "adminSettings.update"
    #   assert moderation_log["action_display_text"] == "updated forum settings"
    #   assert moderation_log["action_display_url"] == "admin-settings"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'adminSettings.addToBlacklist', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 21})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 21
    #   assert moderation_log["action_type"] == "adminSettings.addToBlacklist"
    #   assert moderation_log["action_display_text"] == "added ip blacklist rule named 'test_note'"
    #   assert moderation_log["action_display_url"] == "admin-settings.advanced"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'adminSettings.updateBlacklist', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 22})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 22
    #   assert moderation_log["action_type"] == "adminSettings.updateBlacklist"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "updated ip blacklist rule named 'test_note'"
    #
    #   assert moderation_log["action_display_url"] == "admin-settings.advanced"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'adminSettings.deleteFromBlacklist', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 23})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 23
    #   assert moderation_log["action_type"] == "adminSettings.deleteFromBlacklist"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "deleted ip blacklist rule named 'test_note'"
    #
    #   assert moderation_log["action_display_url"] == "admin-settings.advanced"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'adminSettings.setTheme', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 24})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 24
    #   assert moderation_log["action_type"] == "adminSettings.setTheme"
    #   assert moderation_log["action_display_text"] == "updated the forum theme"
    #   assert moderation_log["action_display_url"] == "admin-settings.theme"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'adminSettings.resetTheme', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 25})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 25
    #   assert moderation_log["action_type"] == "adminSettings.resetTheme"
    #   assert moderation_log["action_display_text"] == "restored the forum to the default theme"
    #   assert moderation_log["action_display_url"] == "admin-settings.theme"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'adminUsers.addRoles', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 26})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 26
    #   assert moderation_log["action_type"] == "adminUsers.addRoles"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "added role '#{@super_admin_role.name}' to users(s) '#{@user.username}'"
    #
    #   assert moderation_log["action_display_url"] == "admin-management.roles({ roleId: '#{@super_admin_role.id}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'adminUsers.removeRoles', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 27})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 27
    #   assert moderation_log["action_type"] == "adminUsers.removeRoles"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "removed role '#{@super_admin_role.name}' from user '#{@user.username}'"
    #
    #   assert moderation_log["action_display_url"] == "admin-management.roles({ roleId: '#{@super_admin_role.id}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'userNotes.create', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 28})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 28
    #   assert moderation_log["action_type"] == "userNotes.create"
    #   assert moderation_log["action_display_text"] == "created a moderation note for user '#{@user.username}'"
    #   assert moderation_log["action_display_url"] == "profile({ username: '#{@user.username}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'userNotes.update', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 29})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 29
    #   assert moderation_log["action_type"] == "userNotes.update"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "edited their moderation note for user '#{@user.username}'"
    #
    #   assert moderation_log["action_display_url"] == "profile({ username: '#{@user.username}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'userNotes.delete', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 30})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 30
    #   assert moderation_log["action_type"] == "userNotes.delete"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "deleted their moderation note for user '#{@user.username}'"
    #
    #   assert moderation_log["action_display_url"] == "profile({ username: '#{@user.username}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'bans.addAddresses', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 31})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 31
    #   assert moderation_log["action_type"] == "bans.addAddresses"
    #   assert moderation_log["action_display_text"] == "banned the following addresses '#{@banned_address}'"
    #   assert moderation_log["action_display_url"] == "admin-management.banned-addresses"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'bans.editAddress', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 32})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 32
    #   assert moderation_log["action_type"] == "bans.editAddress"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "edited banned address '#{@banned_address}' to 'not decay' with a weight of '#{@weight}'"
    #
    #   assert moderation_log["action_display_url"] ==
    #            "admin-management.banned-addresses({ search: '#{@banned_address}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'bans.deleteAddress', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 33})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 33
    #   assert moderation_log["action_type"] == "bans.deleteAddress"
    #   assert moderation_log["action_display_text"] == "deleted banned address '#{@banned_address}'"
    #   assert moderation_log["action_display_url"] == "admin-management.banned-addresses"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'bans.ban', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 34})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 34
    #   assert moderation_log["action_type"] == "bans.ban"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "temporarily banned user '#{@user.username}' until '#{@ban_expiration}'"
    #
    #   assert moderation_log["action_display_url"] == "profile({ username: '#{@user.username}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'bans.unban', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 35})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 35
    #   assert moderation_log["action_type"] == "bans.unban"
    #   assert moderation_log["action_display_text"] == "unbanned user '#{@user.username}'"
    #   assert moderation_log["action_display_url"] == "profile({ username: '#{@user.username}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'bans.banFromBoards', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 36})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 36
    #   assert moderation_log["action_type"] == "bans.banFromBoards"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "banned user '#{@user.username}' from boards: #{@board.name}'"
    #
    #   assert moderation_log["action_display_url"] == "^.board-bans"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'bans.unbanFromBoards', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 37})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 37
    #   assert moderation_log["action_type"] == "bans.unbanFromBoards"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "unbanned user '#{@user.username}' from boards: #{@board.name}'"
    #
    #   assert moderation_log["action_display_url"] == "^.board-bans"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'boards.create', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 38})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 38
    #   assert moderation_log["action_type"] == "boards.create"
    #   assert moderation_log["action_display_text"] == "created board named '#{@board.name}'"
    #   assert moderation_log["action_display_url"] == "admin-management.boards"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'boards.update', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 39})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 39
    #   assert moderation_log["action_type"] == "boards.update"
    #   assert moderation_log["action_display_text"] == "updated board named '#{@board.name}'"
    #   assert moderation_log["action_display_url"] == "admin-management.boards"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'boards.delete', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 40})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 40
    #   assert moderation_log["action_type"] == "boards.delete"
    #   assert moderation_log["action_display_text"] == "deleted board named '#{@board.name}'"
    #   assert moderation_log["action_display_url"] == "admin-management.boards"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'threads.title', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 41})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 41
    #   assert moderation_log["action_type"] == "threads.title"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "updated the title of a thread created by user '#{@user.username}' to '#{@new_thread.title}'"
    #
    #   assert moderation_log["action_display_url"] == "posts.data({ slug: '#{@thread.slug}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'threads.lock', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 42})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 42
    #   assert moderation_log["action_type"] == "threads.lock"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "'locked' the thread '#{@thread.title}' created by user '#{@user.username}'"
    #
    #   assert moderation_log["action_display_url"] == "posts.data({ slug: '#{@thread.slug}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'threads.sticky', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 43})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 43
    #   assert moderation_log["action_type"] == "threads.sticky"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "'stickied' the thread '#{@thread.title}' created by user '#{@user.username}'"
    #
    #   assert moderation_log["action_display_url"] == "posts.data({ slug: '#{@thread.slug}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'threads.move', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 44})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 44
    #   assert moderation_log["action_type"] == "threads.move"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "moved the thread '#{@thread.title}' created by user '#{@user.username}' from board '#{@old_board.name}' to '#{@board.name}'"
    #
    #   assert moderation_log["action_display_url"] == "posts.data({ slug: '#{@thread.slug}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'threads.purge', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 45})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 45
    #   assert moderation_log["action_type"] == "threads.purge"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "purged thread '#{@thread.title}' created by user '#{@user.username}' from board '#{@old_board.name}' to '#{@board.name}'"
    #
    #   assert moderation_log["action_display_url"] == nil
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'threads.editPoll', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 46})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 46
    #   assert moderation_log["action_type"] == "threads.editPoll"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "edited a poll in thread named '#{@thread.title}' created by user '#{@user.username}'"
    #
    #   assert moderation_log["action_display_url"] == "posts.data({ slug: '#{@thread.slug}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'threads.createPoll', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 47})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 47
    #   assert moderation_log["action_type"] == "threads.createPoll"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "created a poll in thread named '#{@thread.title}' created by user '#{@user.username}'"
    #
    #   assert moderation_log["action_display_url"] == "posts.data({ slug: '#{@thread.slug}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'threads.lockPoll', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 48})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 48
    #   assert moderation_log["action_type"] == "threads.lockPoll"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "'unlocked' poll in thread named '#{@thread.title}' created by user '#{@user.username}'"
    #
    #   assert moderation_log["action_display_url"] == "posts.data({ slug: '#{@thread.slug}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'posts.update', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 49})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 49
    #   assert moderation_log["action_type"] == "posts.update"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "updated post created by user '#{@user.username}' in thread named '#{@thread.title}'"
    #
    #   assert moderation_log["action_display_url"] ==
    #            "posts.data({ slug: '#{@thread.slug}', start: '1', '#': '1' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'posts.delete', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 50})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 50
    #   assert moderation_log["action_type"] == "posts.delete"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "hid post created by user '#{@user.username}' in thread '#{@thread.title}'"
    #
    #   assert moderation_log["action_display_url"] ==
    #            "posts.data({ slug: '#{@thread.slug}', start: '1', '#': '1' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'posts.undelete', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 51})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 51
    #   assert moderation_log["action_type"] == "posts.undelete"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "unhid post created by user '#{@user.username}' in thread '#{@thread.title}'"
    #
    #   assert moderation_log["action_display_url"] ==
    #            "posts.data({ slug: '#{@thread.slug}', start: '1', '#': '1' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'posts.purge', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 52})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 52
    #   assert moderation_log["action_type"] == "posts.purge"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "purged post created by user '#{@user.username}' in thread '#{@thread.title}'"
    #
    #   assert moderation_log["action_display_url"] == "posts.data({ slug: '#{@thread.slug}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'users.update', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 53})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 53
    #   assert moderation_log["action_type"] == "users.update"
    #   assert moderation_log["action_display_text"] == "Updated user account '#{@user.username}'"
    #   assert moderation_log["action_display_url"] == "profile({ username: '#{@user.username}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'users.deactivate', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 54})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 54
    #   assert moderation_log["action_type"] == "users.deactivate"
    #   assert moderation_log["action_display_text"] == "deactivated user account '#{@user.username}'"
    #   assert moderation_log["action_display_url"] == "profile({ username: '#{@user.username}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'users.reactivate', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 55})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 55
    #   assert moderation_log["action_type"] == "users.reactivate"
    #   assert moderation_log["action_display_text"] == "reactivated user account '#{@user.username}'"
    #   assert moderation_log["action_display_url"] == "profile({ username: '#{@user.username}' })"
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'users.delete', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 56})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 56
    #   assert moderation_log["action_type"] == "users.delete"
    #   assert moderation_log["action_display_text"] == "purged user account '#{@user.username}'"
    #   assert moderation_log["action_display_url"] == nil
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'conversations.delete', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 57})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 57
    #   assert moderation_log["action_type"] == "conversations.delete"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "deleted conversation between users '#{@admin.username}' and '#{@user.username}'"
    #
    #   assert moderation_log["action_display_url"] == nil
    # end
    #
    # @tag :authenticated
    # test "when action_type is 'messages.delete', gets page",
    #      %{
    #        conn: conn
    #      } do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => 58})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   moderation_log = List.first(moderation_logs)
    #
    #   assert moderation_log["mod_id"] == 58
    #   assert moderation_log["action_type"] == "messages.delete"
    #
    #   assert moderation_log["action_display_text"] ==
    #            "deleted message sent between users '#{@admin.username}' and '#{@user.username}'"
    #
    #   assert moderation_log["action_display_url"] == nil
    # end
    #
    # @tag :authenticated
    # test "given a valid id for 'mod', returns correct moderation_log entry",
    #      %{conn: conn} do
    #   conn = get(conn, Routes.moderation_log_path(conn, :page, %{"mod" => 1}))
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   assert List.first(moderation_logs)["mod_id"] == 1
    # end
    #
    # @tag :authenticated
    # test "given an invalid id for 'mod', returns an empty list",
    #      %{conn: conn} do
    #   conn = get(conn, Routes.moderation_log_path(conn, :page, %{"mod" => 999}))
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   assert Enum.empty?(moderation_logs) == true
    # end
    #
    # @tag :authenticated
    # test "given a valid username for 'mod', returns correct moderation_log entry",
    #      %{conn: conn} do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => "one.adminBoards.updateCategories"})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   assert List.first(moderation_logs)["mod_username"] == "one.adminBoards.updateCategories"
    # end
    #
    # @tag :authenticated
    # test "given an invalid string for 'mod', returns an empty list",
    #      %{conn: conn} do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"mod" => "test_username"})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   assert Enum.empty?(moderation_logs) == true
    # end
    #
    # @tag :authenticated
    # test "given a valid action_type 'action', returns correct moderation_log entry",
    #      %{conn: conn} do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"action" => "adminModerators.remove"})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   assert List.first(moderation_logs)["action_type"] == "adminModerators.remove"
    # end
    #
    # @tag :authenticated
    # test "given a valid action_display_text 'keyword', returns correct moderation_log entry",
    #      %{conn: conn} do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"keyword" => "updated the forum theme"})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   assert List.first(moderation_logs)["action_type"] == "adminSettings.setTheme"
    #   assert List.first(moderation_logs)["action_display_text"] == "updated the forum theme"
    # end
    #
    # @tag :authenticated
    # test "given an invalid 'keyword', returns an empty list",
    #      %{conn: conn} do
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(conn, :page, %{"keyword" => "invalid_keyword"})
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   assert Enum.empty?(moderation_logs) == true
    # end
    #
    # @tag :authenticated
    # test "given a future 'before date', returns correct moderation_log entries",
    #      %{conn: conn} do
    #   datetime = NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), 2, :day))
    #
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(
    #         conn,
    #         :page,
    #         %{
    #           "bdate" => List.first(String.split(datetime)),
    #           "page" => 1,
    #           "limit" => 100
    #         }
    #       )
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   assert length(moderation_logs) == 58
    # end
    #
    # @tag :authenticated
    # test "given a past 'before date', returns an empty list",
    #      %{conn: conn} do
    #   datetime = NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), -2, :day))
    #
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(
    #         conn,
    #         :page,
    #         %{
    #           "bdate" => List.first(String.split(datetime))
    #         }
    #       )
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   assert Enum.empty?(moderation_logs) == true
    # end
    #
    # @tag :authenticated
    # test "given a past 'after date', returns correct moderation_log entries",
    #      %{conn: conn} do
    #   datetime = NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), -2, :day))
    #
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(
    #         conn,
    #         :page,
    #         %{
    #           "adate" => List.first(String.split(datetime)),
    #           "page" => 1,
    #           "limit" => 100
    #         }
    #       )
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   assert length(moderation_logs) == 58
    # end
    #
    # @tag :authenticated
    # test "given a future 'after date', returns an empty list",
    #      %{conn: conn} do
    #   datetime = NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), 2, :day))
    #
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(
    #         conn,
    #         :page,
    #         %{
    #           "adate" => List.first(String.split(datetime))
    #         }
    #       )
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   assert Enum.empty?(moderation_logs) == true
    # end
    #
    # @tag :authenticated
    # test "given a valid date range, returns correct moderation_log entries",
    #      %{conn: conn} do
    #   start_datetime =
    #     NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), -2, :day))
    #
    #   end_datetime = NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), 2, :day))
    #
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(
    #         conn,
    #         :page,
    #         %{
    #           "sdate" => List.first(String.split(start_datetime)),
    #           "edate" => List.first(String.split(end_datetime)),
    #           "page" => 1,
    #           "limit" => 100
    #         }
    #       )
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   assert length(moderation_logs) == 58
    # end
    #
    # @tag :authenticated
    # test "given an invalid date range, returns an empty list",
    #      %{conn: conn} do
    #   start_datetime =
    #     NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), 2, :day))
    #
    #   end_datetime = NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), 4, :day))
    #
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(
    #         conn,
    #         :page,
    #         %{
    #           "sdate" => List.first(String.split(start_datetime)),
    #           "edate" => List.first(String.split(end_datetime))
    #         }
    #       )
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   assert Enum.empty?(moderation_logs) == true
    # end
    #
    # @tag :authenticated
    # test "given an valid id and date range, returns correct moderation_log",
    #      %{conn: conn} do
    #   start_datetime =
    #     NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), -2, :day))
    #
    #   end_datetime = NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), 2, :day))
    #
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(
    #         conn,
    #         :page,
    #         %{
    #           "mod" => 5,
    #           "sdate" => List.first(String.split(start_datetime)),
    #           "edate" => List.first(String.split(end_datetime))
    #         }
    #       )
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   assert List.first(moderation_logs)["mod_id"] == 5
    # end
    #
    # @tag :authenticated
    # test "given a valid username and date range, returns correct moderation_log",
    #      %{conn: conn} do
    #   start_datetime =
    #     NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), -2, :day))
    #
    #   end_datetime = NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), 2, :day))
    #
    #   conn =
    #     get(
    #       conn,
    #       Routes.moderation_log_path(
    #         conn,
    #         :page,
    #         %{
    #           "mod" => "one.adminBoards.updateCategories",
    #           "sdate" => List.first(String.split(start_datetime)),
    #           "edate" => List.first(String.split(end_datetime))
    #         }
    #       )
    #     )
    #
    #   moderation_logs = json_response(conn, 200)["moderation_logs"]
    #   assert List.first(moderation_logs)["mod_username"] == "one.adminBoards.updateCategories"
    # end
  end

  # describe "create/1" do
  #   test "creates moderation_log entry", %{} do
  #     {:ok, moderation_log} = ModerationLog.create(@create_update_boards_attrs)
  #     assert moderation_log.mod_username == @create_update_boards_attrs.mod.username
  #     assert moderation_log.mod_id == @create_update_boards_attrs.mod.id
  #     assert moderation_log.mod_ip == @create_update_boards_attrs.mod.ip
  #     assert moderation_log.action_api_url == @create_update_boards_attrs.action.api_url
  #     assert moderation_log.action_api_method == @create_update_boards_attrs.action.api_method
  #     assert moderation_log.action_obj == @create_update_boards_attrs.action.obj
  #     assert moderation_log.action_type == @create_update_boards_attrs.action.type
  #     assert moderation_log.action_display_text == "updated boards and categories"
  #     assert moderation_log.action_display_url == "admin-management.boards"
  #   end
  #
  #   test "creates moderation_log using helper data_query function",
  #        %{} do
  #     {:ok, moderation_log} = ModerationLog.create(@create_add_moderators_attrs)
  #     assert moderation_log.mod_username == @create_add_moderators_attrs.mod.username
  #     assert moderation_log.mod_id == @create_add_moderators_attrs.mod.id
  #     assert moderation_log.mod_ip == @create_add_moderators_attrs.mod.ip
  #     assert moderation_log.action_api_url == @create_add_moderators_attrs.action.api_url
  #     assert moderation_log.action_api_method == @create_add_moderators_attrs.action.api_method
  #     assert moderation_log.action_type == @create_add_moderators_attrs.action.type
  #   end
  # end
end
