defmodule EpochtalkServerWeb.ThreadView do
  use EpochtalkServerWeb, :view

  @moduledoc """
  Renders and formats `Thread` data, in JSON format for frontend
  """

  @doc """
  Renders whatever data it is passed when template not found. Data pass through
  for rendering misc responses (ex: {found: true} or {success: true})
  ## Example
      iex> EpochtalkServerWeb.ThreadView.render("DoesNotExist.json", data: %{anything: "abc"})
      %{anything: "abc"}
      iex> EpochtalkServerWeb.ThreadView.render("DoesNotExist.json", data: %{success: true})
      %{success: true}
  """
  def template_not_found(_template, %{data: data}), do: data

  @doc """
  Renders recent `Thread` data.
  """
  def render("recent.json", %{
        threads: threads
      }) do
    threads
    |> Enum.map(fn thread ->
      %{id: thread.id, slug: thread.slug, updated_at: thread.updated_at}
    end)
  end
end
