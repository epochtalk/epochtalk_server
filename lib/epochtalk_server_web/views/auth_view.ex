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
      avatar: Map.get(user, :avatar), # user.avatar
      permissions: %{}, # user.permissions
      moderating: Map.get(user, :moderating), # user.moderating
      roles: user.roles,
      ban_expiration: Map.get(user, :ban_expiration),
      malicious_score: Map.get(user, :malicious_score)
    }
  end
end
