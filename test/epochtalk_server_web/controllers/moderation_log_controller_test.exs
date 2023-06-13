defmodule EpochtalkServerWeb.ModerationLogControllerTest do
  use EpochtalkServerWeb.ConnCase, async: true
  alias EpochtalkServer.Models.ModerationLog

  @create_update_boards_attrs %{
    mod: %{username: "mod", id: 1, ip: "127.0.0.1"},
    action: %{
      api_url: "/api/boards/all",
      api_method: "post",
      type: "adminBoards.updateCategories",
      obj: %{}
    }
  }

  @create_add_moderators_attrs %{
    mod: %{username: "test", id: 2, ip: "127.0.0.1"},
    action: %{
      api_url: "/api/admin/moderators",
      api_method: "post",
      type: "adminModerators.add",
      obj: %{
        usernames: ["test"],
        board_id: 1
      }
    }
  }

  describe "page/1" do
    @tag :authenticated
    test "success if display text and url matches for 'adminBoards.updateCategories' action_type",
         %{conn: conn} do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 1})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 1
      assert moderation_log["action_type"] == "adminBoards.updateCategories"
      assert moderation_log["action_display_text"] == "updated boards and categories"
      assert moderation_log["action_display_url"] == "admin-management.boards"
    end

    @tag :authenticated
    test "success if display text and url matches for 'adminModerators.add' action_type",
         %{conn: conn} do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => "three.adminModerators.add"})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 5
      assert moderation_log["action_type"] == "adminModerators.add"

      assert moderation_log["action_display_text"] ==
               "added user(s) 'test' to list of moderators for board 'General Discussion'"

      assert moderation_log["action_display_url"] ==
               "threads.data({ boardSlug: 'general-discussion' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'adminModerators.remove' action_type",
         %{conn: conn} do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 6})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 6
      assert moderation_log["action_type"] == "adminModerators.remove"

      assert moderation_log["action_display_text"] ==
               "removed user(s) 'test' from list of moderators for board 'General Discussion'"

      assert moderation_log["action_display_url"] ==
               "threads.data({ boardSlug: 'general-discussion' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'reports.updateMessageReport' action_type",
         %{conn: conn} do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 7})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 7
      assert moderation_log["action_type"] == "reports.updateMessageReport"

      assert moderation_log["action_display_text"] ==
               "updated the status of message report to 'test'"

      assert moderation_log["action_display_url"] == "^.messages({ reportId: '1' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'reports.createMessageReportNote' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 8})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 8
      assert moderation_log["action_type"] == "reports.createMessageReportNote"
      assert moderation_log["action_display_text"] == "created a note on a message report"
      assert moderation_log["action_display_url"] == "^.messages({ reportId: '1' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'reports.updateMessageReportNote' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 9})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 9
      assert moderation_log["action_type"] == "reports.updateMessageReportNote"
      assert moderation_log["action_display_text"] == "edited their note on a message report"
      assert moderation_log["action_display_url"] == "^.messages({ reportId: '1' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'reports.updatePostReport' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 10})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 10
      assert moderation_log["action_type"] == "reports.updatePostReport"

      assert moderation_log["action_display_text"] ==
               "updated the status of post report to 'test'"

      assert moderation_log["action_display_url"] == "^.messages({ reportId: '1' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'reports.createPostReportNote' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 11})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 11
      assert moderation_log["action_type"] == "reports.createPostReportNote"
      assert moderation_log["action_display_text"] == "created a note on a post report"
      assert moderation_log["action_display_url"] == "^.messages({ reportId: '1' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'reports.updatePostReportNote' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 12})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 12
      assert moderation_log["action_type"] == "reports.updatePostReportNote"
      assert moderation_log["action_display_text"] == "edited their note on a post report"
      assert moderation_log["action_display_url"] == "^.messages({ reportId: '1' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'reports.updateUserReport' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 13})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 13
      assert moderation_log["action_type"] == "reports.updateUserReport"

      assert moderation_log["action_display_text"] ==
               "updated the status of user report to 'test'"

      assert moderation_log["action_display_url"] == "^.messages({ reportId: '1' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'reports.createUserReportNote' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 14})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 14
      assert moderation_log["action_type"] == "reports.createUserReportNote"
      assert moderation_log["action_display_text"] == "created a note on a user report"
      assert moderation_log["action_display_url"] == "^.messages({ reportId: '1' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'reports.updateUserReportNote' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 15})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 15
      assert moderation_log["action_type"] == "reports.updateUserReportNote"
      assert moderation_log["action_display_text"] == "edited their note on a user report"
      assert moderation_log["action_display_url"] == "^.messages({ reportId: '1' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'adminRoles.add' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 16})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 16
      assert moderation_log["action_type"] == "adminRoles.add"
      assert moderation_log["action_display_text"] == "created a new role named 'test'"
      assert moderation_log["action_display_url"] == "admin-management.roles({ roleId: '1' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'adminRoles.remove' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 17})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 17
      assert moderation_log["action_type"] == "adminRoles.remove"
      assert moderation_log["action_display_text"] == "removed the role named 'test'"
      assert moderation_log["action_display_url"] == "admin-management.roles"
    end

    @tag :authenticated
    test "success if display text and url matches for 'adminRoles.update' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 18})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 18
      assert moderation_log["action_type"] == "adminRoles.update"
      assert moderation_log["action_display_text"] == "updated the role named 'test'"
      assert moderation_log["action_display_url"] == "admin-management.roles({ roleId: '1' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'adminRoles.reprioritize' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 19})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 19
      assert moderation_log["action_type"] == "adminRoles.reprioritize"
      assert moderation_log["action_display_text"] == "reordered role priorities"
      assert moderation_log["action_display_url"] == "admin-management.roles"
    end

    @tag :authenticated
    test "success if display text and url matches for 'adminSettings.update' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 20})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 20
      assert moderation_log["action_type"] == "adminSettings.update"
      assert moderation_log["action_display_text"] == "updated forum settings"
      assert moderation_log["action_display_url"] == "admin-settings"
    end

    @tag :authenticated
    test "success if display text and url matches for 'adminSettings.addToBlacklist' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 21})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 21
      assert moderation_log["action_type"] == "adminSettings.addToBlacklist"
      assert moderation_log["action_display_text"] == "added ip blacklist rule named 'test_note'"
      assert moderation_log["action_display_url"] == "admin-settings.advanced"
    end

    @tag :authenticated
    test "success if display text and url matches for 'adminSettings.updateBlacklist' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 22})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 22
      assert moderation_log["action_type"] == "adminSettings.updateBlacklist"

      assert moderation_log["action_display_text"] ==
               "updated ip blacklist rule named 'test_note'"

      assert moderation_log["action_display_url"] == "admin-settings.advanced"
    end

    @tag :authenticated
    test "success if display text and url matches for 'adminSettings.deleteFromBlacklist' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 23})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 23
      assert moderation_log["action_type"] == "adminSettings.deleteFromBlacklist"

      assert moderation_log["action_display_text"] ==
               "deleted ip blacklist rule named 'test_note'"

      assert moderation_log["action_display_url"] == "admin-settings.advanced"
    end

    @tag :authenticated
    test "success if display text and url matches for 'adminSettings.setTheme' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 24})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 24
      assert moderation_log["action_type"] == "adminSettings.setTheme"
      assert moderation_log["action_display_text"] == "updated the forum theme"
      assert moderation_log["action_display_url"] == "admin-settings.theme"
    end

    @tag :authenticated
    test "success if display text and url matches for 'adminSettings.resetTheme' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 25})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 25
      assert moderation_log["action_type"] == "adminSettings.resetTheme"
      assert moderation_log["action_display_text"] == "restored the forum to the default theme"
      assert moderation_log["action_display_url"] == "admin-settings.theme"
    end

    @tag :authenticated
    test "success if display text and url matches for 'adminUsers.addRoles' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 26})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 26
      assert moderation_log["action_type"] == "adminUsers.addRoles"

      assert moderation_log["action_display_text"] ==
               "added role 'Super Administrator' to users(s) 'test'"

      assert moderation_log["action_display_url"] == "admin-management.roles({ roleId: '1' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'adminUsers.removeRoles' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 27})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 27
      assert moderation_log["action_type"] == "adminUsers.removeRoles"

      assert moderation_log["action_display_text"] ==
               "removed role 'Super Administrator' from user 'test'"

      assert moderation_log["action_display_url"] == "admin-management.roles({ roleId: '1' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'userNotes.create' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 28})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 28
      assert moderation_log["action_type"] == "userNotes.create"
      assert moderation_log["action_display_text"] == "created a moderation note for user 'test'"
      assert moderation_log["action_display_url"] == "profile({ username: 'test' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'userNotes.update' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 29})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 29
      assert moderation_log["action_type"] == "userNotes.update"

      assert moderation_log["action_display_text"] ==
               "edited their moderation note for user 'test'"

      assert moderation_log["action_display_url"] == "profile({ username: 'test' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'userNotes.delete' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 30})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 30
      assert moderation_log["action_type"] == "userNotes.delete"

      assert moderation_log["action_display_text"] ==
               "deleted their moderation note for user 'test'"

      assert moderation_log["action_display_url"] == "profile({ username: 'test' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'bans.addAddresses' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 31})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 31
      assert moderation_log["action_type"] == "bans.addAddresses"
      assert moderation_log["action_display_text"] == "banned the following addresses '127.0.0.1'"
      assert moderation_log["action_display_url"] == "admin-management.banned-addresses"
    end

    @tag :authenticated
    test "success if display text and url matches for 'bans.editAddress' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 32})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 32
      assert moderation_log["action_type"] == "bans.editAddress"

      assert moderation_log["action_display_text"] ==
               "edited banned address '127.0.0.1' to 'not decay' with a weight of '99'"

      assert moderation_log["action_display_url"] ==
               "admin-management.banned-addresses({ search: '127.0.0.1' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'bans.deleteAddress' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 33})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 33
      assert moderation_log["action_type"] == "bans.deleteAddress"
      assert moderation_log["action_display_text"] == "deleted banned address '127.0.0.1'"
      assert moderation_log["action_display_url"] == "admin-management.banned-addresses"
    end

    @tag :authenticated
    test "success if display text and url matches for 'bans.ban' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 34})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 34
      assert moderation_log["action_type"] == "bans.ban"

      assert moderation_log["action_display_text"] ==
               "temporarily banned user 'test' until '31 Dec 2030'"

      assert moderation_log["action_display_url"] == "profile({ username: 'test' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'bans.unban' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 35})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 35
      assert moderation_log["action_type"] == "bans.unban"
      assert moderation_log["action_display_text"] == "unbanned user 'test'"
      assert moderation_log["action_display_url"] == "profile({ username: 'test' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'bans.banFromBoards' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 36})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 36
      assert moderation_log["action_type"] == "bans.banFromBoards"

      assert moderation_log["action_display_text"] ==
               "banned user 'test' from boards: General Discussion'"

      assert moderation_log["action_display_url"] == "^.board-bans"
    end

    @tag :authenticated
    test "success if display text and url matches for 'bans.unbanFromBoards' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 37})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 37
      assert moderation_log["action_type"] == "bans.unbanFromBoards"

      assert moderation_log["action_display_text"] ==
               "unbanned user 'test' from boards: General Discussion'"

      assert moderation_log["action_display_url"] == "^.board-bans"
    end

    @tag :authenticated
    test "success if display text and url matches for 'boards.create' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 38})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 38
      assert moderation_log["action_type"] == "boards.create"
      assert moderation_log["action_display_text"] == "created board named 'test_board'"
      assert moderation_log["action_display_url"] == "admin-management.boards"
    end

    @tag :authenticated
    test "success if display text and url matches for 'boards.update' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 39})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 39
      assert moderation_log["action_type"] == "boards.update"
      assert moderation_log["action_display_text"] == "updated board named 'test_board'"
      assert moderation_log["action_display_url"] == "admin-management.boards"
    end

    @tag :authenticated
    test "success if display text and url matches for 'boards.delete' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 40})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 40
      assert moderation_log["action_type"] == "boards.delete"
      assert moderation_log["action_display_text"] == "deleted board named 'test_board'"
      assert moderation_log["action_display_url"] == "admin-management.boards"
    end

    @tag :authenticated
    test "success if display text and url matches for 'threads.title' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 41})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 41
      assert moderation_log["action_type"] == "threads.title"

      assert moderation_log["action_display_text"] ==
               "updated the title of a thread created by user 'test' to 'new_title'"

      assert moderation_log["action_display_url"] == "posts.data({ slug: 'test_slug' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'threads.lock' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 42})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 42
      assert moderation_log["action_type"] == "threads.lock"

      assert moderation_log["action_display_text"] ==
               "'locked' the thread 'test' created by user 'test'"

      assert moderation_log["action_display_url"] == "posts.data({ slug: 'test_slug' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'threads.sticky' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 43})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 43
      assert moderation_log["action_type"] == "threads.sticky"

      assert moderation_log["action_display_text"] ==
               "'stickied' the thread 'test' created by user 'test'"

      assert moderation_log["action_display_url"] == "posts.data({ slug: 'test_slug' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'threads.move' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 44})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 44
      assert moderation_log["action_type"] == "threads.move"

      assert moderation_log["action_display_text"] ==
               "moved the thread 'new_title' created by user 'test' from board 'old_board' to 'General Discussion'"

      assert moderation_log["action_display_url"] == "posts.data({ slug: 'test_slug' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'threads.purge' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 45})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 45
      assert moderation_log["action_type"] == "threads.purge"

      assert moderation_log["action_display_text"] ==
               "purged thread 'title' created by user 'test' from board 'old_board' to 'General Discussion'"

      assert moderation_log["action_display_url"] == nil
    end

    @tag :authenticated
    test "success if display text and url matches for 'threads.editPoll' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 46})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 46
      assert moderation_log["action_type"] == "threads.editPoll"

      assert moderation_log["action_display_text"] ==
               "edited a poll in thread named 'test' created by user 'test'"

      assert moderation_log["action_display_url"] == "posts.data({ slug: 'test_slug' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'threads.createPoll' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 47})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 47
      assert moderation_log["action_type"] == "threads.createPoll"

      assert moderation_log["action_display_text"] ==
               "created a poll in thread named 'test' created by user 'test'"

      assert moderation_log["action_display_url"] == "posts.data({ slug: 'test_slug' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'threads.lockPoll' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 48})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 48
      assert moderation_log["action_type"] == "threads.lockPoll"

      assert moderation_log["action_display_text"] ==
               "'unlocked' poll in thread named 'test' created by user 'test'"

      assert moderation_log["action_display_url"] == "posts.data({ slug: 'test_slug' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'posts.update' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 49})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 49
      assert moderation_log["action_type"] == "posts.update"

      assert moderation_log["action_display_text"] ==
               "updated post created by user 'test' in thread named 'test'"

      assert moderation_log["action_display_url"] ==
               "posts.data({ slug: 'test_slug', start: '1', '#': '1' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'posts.delete' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 50})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 50
      assert moderation_log["action_type"] == "posts.delete"

      assert moderation_log["action_display_text"] ==
               "hid post created by user 'test' in thread 'test'"

      assert moderation_log["action_display_url"] ==
               "posts.data({ slug: 'test_slug', start: '1', '#': '1' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'posts.undelete' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 51})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 51
      assert moderation_log["action_type"] == "posts.undelete"

      assert moderation_log["action_display_text"] ==
               "unhid post created by user 'test' in thread 'test'"

      assert moderation_log["action_display_url"] ==
               "posts.data({ slug: 'test_slug', start: '1', '#': '1' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'posts.purge' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 52})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 52
      assert moderation_log["action_type"] == "posts.purge"

      assert moderation_log["action_display_text"] ==
               "purged post created by user 'test' in thread 'test'"

      assert moderation_log["action_display_url"] == "posts.data({ slug: 'test_slug' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'users.update' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 53})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 53
      assert moderation_log["action_type"] == "users.update"
      assert moderation_log["action_display_text"] == "Updated user account 'test'"
      assert moderation_log["action_display_url"] == "profile({ username: 'test' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'users.deactivate' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 54})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 54
      assert moderation_log["action_type"] == "users.deactivate"
      assert moderation_log["action_display_text"] == "deactivated user account 'test'"
      assert moderation_log["action_display_url"] == "profile({ username: 'test' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'users.reactivate' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 55})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 55
      assert moderation_log["action_type"] == "users.reactivate"
      assert moderation_log["action_display_text"] == "reactivated user account 'test'"
      assert moderation_log["action_display_url"] == "profile({ username: 'test' })"
    end

    @tag :authenticated
    test "success if display text and url matches for 'users.delete' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 56})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 56
      assert moderation_log["action_type"] == "users.delete"
      assert moderation_log["action_display_text"] == "purged user account 'test'"
      assert moderation_log["action_display_url"] == nil
    end

    @tag :authenticated
    test "success if display text and url matches for 'conversations.delete' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 57})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 57
      assert moderation_log["action_type"] == "conversations.delete"

      assert moderation_log["action_display_text"] ==
               "deleted conversation between users 'admin' and 'test'"

      assert moderation_log["action_display_url"] == nil
    end

    @tag :authenticated
    test "success if display text and url matches for 'messages.delete' action_type",
         %{
           conn: conn
         } do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => 58})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      moderation_log = List.first(moderation_logs)

      assert moderation_log["mod_id"] == 58
      assert moderation_log["action_type"] == "messages.delete"

      assert moderation_log["action_display_text"] ==
               "deleted message sent between users 'admin' and 'test'"

      assert moderation_log["action_display_url"] == nil
    end

    @tag :authenticated
    test "success if 'mod' query param as an integer returns correct moderation_log entry by id",
         %{conn: conn} do
      conn = get(conn, Routes.moderation_log_path(conn, :page, %{"mod" => 1}))
      moderation_logs = json_response(conn, 200)["moderation_logs"]
      assert List.first(moderation_logs)["mod_id"] == 1
    end

    @tag :authenticated
    test "success if 'mod' query param as an integer returns an empty list for an invalid id",
         %{conn: conn} do
      conn = get(conn, Routes.moderation_log_path(conn, :page, %{"mod" => 999}))
      moderation_logs = json_response(conn, 200)["moderation_logs"]
      assert Enum.empty?(moderation_logs) == true
    end

    @tag :authenticated
    test "success if 'mod' query param as a string returns correct moderation_log entry by username",
         %{conn: conn} do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => "one.adminBoards.updateCategories"})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      assert List.first(moderation_logs)["mod_username"] == "one.adminBoards.updateCategories"
    end

    @tag :authenticated
    test "success if 'mod' query param as a string returns an empty list for an invalid username",
         %{conn: conn} do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"mod" => "test_username"})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      assert Enum.empty?(moderation_logs) == true
    end

    @tag :authenticated
    test "success if 'action' query param returns correct moderation_log entry by action_type",
         %{conn: conn} do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"action" => "adminModerators.remove"})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      assert List.first(moderation_logs)["action_type"] == "adminModerators.remove"
    end

    @tag :authenticated
    test "success if 'keyword' query param returns correct moderation_log entry by action_display_text",
         %{conn: conn} do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"keyword" => "updated the forum theme"})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      assert List.first(moderation_logs)["action_type"] == "adminSettings.setTheme"
      assert List.first(moderation_logs)["action_display_text"] == "updated the forum theme"
    end

    @tag :authenticated
    test "success if 'keyword' query param returns an empty list for an invalid keyword",
         %{conn: conn} do
      conn =
        get(
          conn,
          Routes.moderation_log_path(conn, :page, %{"keyword" => "invalid_keyword"})
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      assert Enum.empty?(moderation_logs) == true
    end

    @tag :authenticated
    test "success if 'before date' query param returns correct moderation_log entries for a date in the future",
         %{conn: conn} do
      datetime = NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), 2, :day))

      conn =
        get(
          conn,
          Routes.moderation_log_path(
            conn,
            :page,
            %{
              "bdate" => List.first(String.split(datetime)),
              "page" => 1,
              "limit" => 100
            }
          )
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      assert length(moderation_logs) == 58
    end

    @tag :authenticated
    test "success if 'before date' query param returns an empty list for a date in the past",
         %{conn: conn} do
      datetime = NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), -2, :day))

      conn =
        get(
          conn,
          Routes.moderation_log_path(
            conn,
            :page,
            %{
              "bdate" => List.first(String.split(datetime))
            }
          )
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      assert Enum.empty?(moderation_logs) == true
    end

    @tag :authenticated
    test "success if 'after date' query param returns correct moderation_log entries for a date in the past",
         %{conn: conn} do
      datetime = NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), -2, :day))

      conn =
        get(
          conn,
          Routes.moderation_log_path(
            conn,
            :page,
            %{
              "adate" => List.first(String.split(datetime)),
              "page" => 1,
              "limit" => 100
            }
          )
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      assert length(moderation_logs) == 58
    end

    @tag :authenticated
    test "success if 'after date' query param returns an empty list for a date in the future",
         %{conn: conn} do
      datetime = NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), 2, :day))

      conn =
        get(
          conn,
          Routes.moderation_log_path(
            conn,
            :page,
            %{
              "adate" => List.first(String.split(datetime))
            }
          )
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      assert Enum.empty?(moderation_logs) == true
    end

    @tag :authenticated
    test "success if date range query param returns correct moderation_log entries for a valid date range",
         %{conn: conn} do
      start_datetime =
        NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), -2, :day))

      end_datetime = NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), 2, :day))

      conn =
        get(
          conn,
          Routes.moderation_log_path(
            conn,
            :page,
            %{
              "sdate" => List.first(String.split(start_datetime)),
              "edate" => List.first(String.split(end_datetime)),
              "page" => 1,
              "limit" => 100
            }
          )
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      assert length(moderation_logs) == 58
    end

    @tag :authenticated
    test "success if date range query param returns an empty list for an invalid date range",
         %{conn: conn} do
      start_datetime =
        NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), 2, :day))

      end_datetime = NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), 4, :day))

      conn =
        get(
          conn,
          Routes.moderation_log_path(
            conn,
            :page,
            %{
              "sdate" => List.first(String.split(start_datetime)),
              "edate" => List.first(String.split(end_datetime))
            }
          )
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      assert Enum.empty?(moderation_logs) == true
    end

    @tag :authenticated
    test "success if id and date range query param returns correct moderation_log for a valid date range",
         %{conn: conn} do
      start_datetime =
        NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), -2, :day))

      end_datetime = NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), 2, :day))

      conn =
        get(
          conn,
          Routes.moderation_log_path(
            conn,
            :page,
            %{
              "mod" => 5,
              "sdate" => List.first(String.split(start_datetime)),
              "edate" => List.first(String.split(end_datetime))
            }
          )
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      assert List.first(moderation_logs)["mod_id"] == 5
    end

    @tag :authenticated
    test "success if username and date range query param returns correct moderation_log for a valid date range",
         %{conn: conn} do
      start_datetime =
        NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), -2, :day))

      end_datetime = NaiveDateTime.to_string(NaiveDateTime.add(NaiveDateTime.utc_now(), 2, :day))

      conn =
        get(
          conn,
          Routes.moderation_log_path(
            conn,
            :page,
            %{
              "mod" => "one.adminBoards.updateCategories",
              "sdate" => List.first(String.split(start_datetime)),
              "edate" => List.first(String.split(end_datetime))
            }
          )
        )

      moderation_logs = json_response(conn, 200)["moderation_logs"]
      assert List.first(moderation_logs)["mod_username"] == "one.adminBoards.updateCategories"
    end
  end

  describe "create/1" do
    test "success if moderation_log entry is created in database", %{} do
      {:ok, moderation_log} = ModerationLog.create(@create_update_boards_attrs)
      assert moderation_log.mod_username == @create_update_boards_attrs.mod.username
      assert moderation_log.mod_id == @create_update_boards_attrs.mod.id
      assert moderation_log.mod_ip == @create_update_boards_attrs.mod.ip
      assert moderation_log.action_api_url == @create_update_boards_attrs.action.api_url
      assert moderation_log.action_api_method == @create_update_boards_attrs.action.api_method
      assert moderation_log.action_obj == @create_update_boards_attrs.action.obj
      assert moderation_log.action_type == @create_update_boards_attrs.action.type
      assert moderation_log.action_display_text == "updated boards and categories"
      assert moderation_log.action_display_url == "admin-management.boards"
    end

    test "success if moderation_log entry is created in database using helper data_query function",
         %{} do
      {:ok, moderation_log} = ModerationLog.create(@create_add_moderators_attrs)
      assert moderation_log.mod_username == @create_add_moderators_attrs.mod.username
      assert moderation_log.mod_id == @create_add_moderators_attrs.mod.id
      assert moderation_log.mod_ip == @create_add_moderators_attrs.mod.ip
      assert moderation_log.action_api_url == @create_add_moderators_attrs.action.api_url
      assert moderation_log.action_api_method == @create_add_moderators_attrs.action.api_method
      assert moderation_log.action_type == @create_add_moderators_attrs.action.type
    end
  end
end
