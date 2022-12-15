defmodule EpochtalkServerWeb.ModerationLogControllerTest do
  use EpochtalkServerWeb.ConnCase, async: false
  alias EpochtalkServer.Models.ModerationLog
  alias EpochtalkServerWeb.Helpers.ModerationLogDisplayData

  @create_update_boards_attrs %{
    mod: %{username: "mod", id: 1, ip: "127.0.0.1"},
    action: %{
      api_url: "/api/boards/all",
      api_method: "post",
      type: "adminBoards.updateCategories",
      obj: %{}
      # display_text: "updated boards and categories",
      # display_url: "admin-management.boards"
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
      # display_text: "added user(s) \"test\" to list of moderators for board \"name\"",
      # display_url: "threads.data({ boardSlug: 'name' })"
    }
  }

  describe "getDisplayData/1" do
    test "success if dislay text and url is generated from ModerationLogDisplayData" do
      action_obj = get_in(@create_update_boards_attrs, [:action, :obj])

      display_data =
        ModerationLogDisplayData.getDisplayData(
          get_in(@create_update_boards_attrs, [:action, :type])
        )

      assert display_data.genDisplayText.(action_obj) == "updated boards and categories"
      assert display_data.genDisplayUrl.(action_obj) == "admin-management.boards"
    end

    test "success if dislay text and url is generated from ModerationLogDisplayData using dataQuery function" do
      display_data =
        ModerationLogDisplayData.getDisplayData(
          get_in(@create_add_moderators_attrs, [:action, :type])
        )

      action_obj =
        if Map.has_key?(display_data, :dataQuery) do
          display_data.dataQuery.(get_in(@create_add_moderators_attrs, [:action, :obj]))
        else
          get_in(@create_add_moderators_attrs, [:action, :obj])
        end

      assert display_data.genDisplayText.(action_obj) ==
               "added user(s) '#{Enum.join(action_obj.usernames, " ")}' to list of moderators for board '#{action_obj.board_name}'"

      assert display_data.genDisplayUrl.(action_obj) ==
               "threads.data({ boardSlug: '#{action_obj.board_slug}' })"
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
  end
end
