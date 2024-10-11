defmodule EpochtalkServerWeb.Controllers.Breadcrumb do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Breadcrumbs` related API requests
  """
  alias EpochtalkServerWeb.Helpers.Breadcrumbs
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.Helpers.Validate

  @doc """
  Used to return breadcrumbs to the frontend`
  """
  def breadcrumbs(conn, attrs) do
    with id <- parse_id(attrs),
         type <- Validate.cast(attrs, "type", :string, required: true),
         {:ok, breadcrumbs} <- Breadcrumbs.build_crumbs(id, type, []) do
      render(conn, :breadcrumbs, breadcrumbs: breadcrumbs)
    else
      {:error, data} ->
        ErrorHelpers.render_json_error(conn, 400, data)

      _ ->
        ErrorHelpers.render_json_error(conn, 500, "There was an issue obtaining the breadcrumbs")
    end
  end

  defp parse_id(attrs) do
    case Integer.parse(attrs["id"]) do
      {_, ""} ->
        Validate.cast(attrs, "id", :integer, min: 1, required: true)

      _ ->
        Validate.cast(attrs, "id", :string, required: true)
    end
  end
end
