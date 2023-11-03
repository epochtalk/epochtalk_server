defmodule EpochtalkServerWeb.Plugs.UserLastActive do
  @moduledoc """
  Plug that updates `User` last active date
  """
  use Plug.Builder
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServer.Models.Profile

  plug(:update_user_last_active)

  @doc """
  Updates `User` last active date
  """
  def update_user_last_active(conn, _opts) do
    user = Guardian.Plug.current_resource(conn)
    # update user last active, if user exists and more than one minute has passed
    Profile.maybe_update_last_active(user)
    conn
  end
end
