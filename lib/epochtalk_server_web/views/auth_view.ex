defmodule EpochtalkServerWeb.AuthView do
  use EpochtalkServerWeb, :view

  def render("search.json", %{found: found}) do
    %{found: found}
  end
  def render("logout.json", _data), do: true
  def render("show.json", %{user: user}) do
    user |> user_json()
  end
  def render("credentials.json", %{user: user}) do
    user |> credentials_json()
  end
  def user_json(user) do
    %{
      id: user.id,
      username: user.username,
          # TODO(boka): fill in these fields
      avatar: "", # user.avatar
      permissions: %{}, # user.permissions
      roles: %{} # user.roles
    }
  end
  defp credentials_json(user) do
    %{
      token: user.token,
      id: user.id,
      username: user.username,
      # TODO: fill in these fields
      avatar: "", # user.avatar
      permissions: %{}, # user.permissions
      moderating: %{}, # user.moderating
      roles: user.roles
    }
  end
end
