defmodule EpochtalkServerWeb.RoleView do
  use EpochtalkServerWeb, :view

  @moduledoc """
  Renders and formats `Role` data, in JSON format for frontend
  """

  @doc """
  Renders whatever data it is passed when template not found. Data pass through
  for rendering misc responses (ex: {found: true} or {success: true})
  ## Example
      iex> EpochtalkServerWeb.RoleView.render("DoesNotExist.json", data: %{anything: "123"})
      %{anything: "123"}
      iex> EpochtalkServerWeb.RoleView.render("DoesNotExist.json", data: %{success: false})
      %{success: false}
  """
  def template_not_found(_template, %{data: data}), do: data
end
