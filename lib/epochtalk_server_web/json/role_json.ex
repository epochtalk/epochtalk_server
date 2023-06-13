defmodule EpochtalkServerWeb.Controllers.RoleJSON do
  @moduledoc """
  Renders and formats `Role` data, in JSON format for frontend
  """

  @doc """
  Renders `Role` update result data in JSON
  """
  def update(%{id: id}), do: id

  @doc """
  Renders `Role` all result data in JSON
  """
  def all(%{roles: roles}), do: roles
end
