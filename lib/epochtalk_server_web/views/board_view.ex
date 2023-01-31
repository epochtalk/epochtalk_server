defmodule EpochtalkServerWeb.BoardView do
  use EpochtalkServerWeb, :view

  @moduledoc """
  Renders and formats `User` data, in JSON format for frontend
  """

  @doc """
  Renders whatever data it is passed when template not found. Data pass through
  for rendering misc responses (ex: {found: true} or {success: true})
  ## Example
      iex> EpochtalkServerWeb.BoardView.render("DoesNotExist.json", data: %{anything: "abc"})
      %{anything: "abc"}
      iex> EpochtalkServerWeb.BoardView.render("DoesNotExist.json", data: %{success: true})
      %{success: true}
  """
  def template_not_found(_template, %{data: data}), do: data
end
