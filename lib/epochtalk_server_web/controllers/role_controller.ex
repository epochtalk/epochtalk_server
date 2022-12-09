defmodule EpochtalkServerWeb.RoleController do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Role` related API requests
  """
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.Helpers.Validate
  alias EpochtalkServer.Models.Role

  @doc """
  Used to update a specific `Role`
  """
  def update(conn, %{"id" => _, "permissions" => permissions} = attrs) do
    with id <- Validate.cast(attrs, "id", :integer, min: 1),
         {:auth, _user} <- {:auth, Guardian.Plug.current_resource(conn)},
         {:ok, data} <- some_func(%Role{id: id, permissions: permissions}) do
      render(conn, "update.json", data: data)
    else
      {:auth, nil} ->
        ErrorHelpers.render_json_error(conn, 400, "Not logged in, cannot update role")
    end
  end

  defp some_func(role), do: {:ok, role}
end
