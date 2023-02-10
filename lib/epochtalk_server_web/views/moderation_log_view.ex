defmodule EpochtalkServerWeb.ModerationLogView do
  use EpochtalkServerWeb, :view

  @moduledoc """
  Renders and formats `ModerationLog` data, in JSON format for frontend
  """

  @doc """
  Renders paginated `ModerationLog` entries.
  """
  def render("page.json", %{moderation_logs: moderation_logs, pagination_data: pagination_data}) do
    %{
      moderation_logs: moderation_logs,
      pagination_data: pagination_data
    }
  end
end
