defmodule EpochtalkServerWeb.AuthView do
  use EpochtalkServerWeb, :view
  alias EpochtalkServer.Models.Role

  def render("search.json", %{found: found}) do
    %{found: found}
  end
  def render("logout.json", _data), do: true
  def render("show.json", %{user: user}) do
    user |> user_json()
  end
  def render("credentials.json", %{user: user}) do
    user |> format_user_reply()
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
  defp format_user_reply(user) do
    reply = %{
      token: user.token,
      id: user.id,
      username: user.username,
      avatar: Map.get(user, :avatar), # user.avatar
      permissions: Role.get_masked_permissions(user.roles), # user.permissions
      moderating: Map.get(user, :moderating), # user.moderating
      roles: Enum.map(user.roles, &(&1.lookup))
    }
    # only append ban_expiration and malicious_score if present
    if exp = Map.get(user, :ban_expiration),
      do: Map.put(reply, :ban_expiration, exp),
      else: reply
    if ms = Map.get(user, :malicious_score),
      do: Map.put(reply, :malicious_score, ms),
      else: reply
  end
end
