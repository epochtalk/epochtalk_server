defmodule EpochtalkServerWeb.Helpers.ModerationLogDisplayData do
  @moduledoc """
  Helper for obtaining display data for ModerationLog entries
  """
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Repo

  def getDisplayData(action_type) do
    case action_type do
      "adminBoards.updateCategories" ->
        %{
          genDisplayText: fn _ -> "updated boards and categories" end,
          genDisplayUrl: fn _ -> "admin-management.boards" end
        }

      # =========== Admin Moderator Routes ===========
      "adminModerators.add" ->
        %{
          genDisplayText: fn data ->
            "added user(s) '#{Enum.join(data.usernames, " ")}' to list of moderators for board '#{data.board_name}'"
          end,
          genDisplayUrl: fn data -> "threads.data({ boardSlug: '#{data.board_slug}' })" end,
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
