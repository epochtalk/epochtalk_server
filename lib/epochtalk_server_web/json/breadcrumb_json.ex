defmodule EpochtalkServerWeb.Controllers.BreadcrumbJSON do
  @moduledoc """
  Renders and formats `Breadcrumb` data, in JSON format for frontend
  """

  @doc """
  Renders `Breadcrumb` entries.
  """
  def breadcrumbs(%{breadcrumbs: breadcrumbs}), do: %{breadcrumbs: breadcrumbs}
end
