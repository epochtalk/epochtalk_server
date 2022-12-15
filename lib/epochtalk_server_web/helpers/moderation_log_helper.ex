defmodule EpochtalkServerWeb.Helpers.ModerationLogHelper do
  @moduledoc """
  Helper for obtaining display data for ModerationLog entries
  """
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Repo

  def get_display_data(action_type) do
    case action_type do
      "adminBoards.updateCategories" ->
        %{
          get_display_text: fn _ -> "updated boards and categories" end,
          get_display_url: fn _ -> "admin-management.boards" end
        }

      # =========== Admin Moderator Routes ===========
      "adminModerators.add" ->
        %{
          get_display_text: fn data ->
            "added user(s) '#{Enum.join(data.usernames, " ")}' to list of moderators for board '#{data.board_name}'"
          end,
          get_display_url: fn data -> "threads.data({ boardSlug: '#{data.board_slug}' })" end,
          dataQuery: fn data ->
            board = Repo.get_by(Board, id: data.board_id)

            data =
              data
              |> Map.put(:board_slug, board.slug)
              |> Map.put(:board_name, board.name)

            data
          end
        }

      _ ->
        nil
    end
  end
end
