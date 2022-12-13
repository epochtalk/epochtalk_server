defmodule EpochtalkServerWeb.ModerationLogControllerTest do
  use EpochtalkServerWeb.ConnCase, async: false
  import Ecto.Changeset
  alias EpochtalkServer.Models.ModerationLog
  alias EpochtalkServer.Repo

  @create_attrs %{mod: %{username: "mod",
                         id: 1,
                         ip: "127.0.0.1"},
                  action: %{api_url: "/api/boards/all",
                            api_method: "post",
                            type: "adminBoards.updateCategories",
                            display_text: "updated boards and categories",
                            display_url: "admin-management.boards"},
                  action_obj: %{}}

  describe "create/1" do
    test "success if moderation_log entry is created in database", %{} do
      {:ok, moderation_log} = ModerationLog.create(@create_attrs)
      assert moderation_log.mod_username == @create_attrs.mod.username
      assert moderation_log.mod_id == @create_attrs.mod.id
      assert moderation_log.mod_ip == @create_attrs.mod.ip
      assert moderation_log.action_api_url == @create_attrs.action.api_url
      assert moderation_log.action_api_method == @create_attrs.action.api_method
      assert moderation_log.action_type == @create_attrs.action.type
      assert moderation_log.action_display_text == @create_attrs.action.display_text
      assert moderation_log.action_display_url == @create_attrs.action.display_url
    end
  end
end
