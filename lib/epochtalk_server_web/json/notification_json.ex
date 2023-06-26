defmodule EpochtalkServerWeb.Controllers.NotificationJSON do
  @moduledoc """
  Renders and formats `User` data, in JSON format for frontend
  """

  @doc """
  Renders `Notification` counts data in JSON
  """
  def counts(%{data: data}), do: data

  @doc """
  Renders `Notification` dismiss data in JSON
  """
  def dismiss(%{success: success}), do: %{success: success}
end
