defmodule EpochtalkServerWeb.AuthView do
  use EpochtalkServerWeb, :view
  alias EpochtalkServer.Models.Role

  def render("search.json", %{found: found}), do: %{found: found}
  def render("logout.json", _data), do: true
  def render("user.json", %{user: user}), do: format_user_reply(user)

  defp format_user_reply(user) do
    reply = %{
      token: user.token,
      id: user.id,
      username: user.username,
      avatar: Map.get(user, :avatar), # user.avatar
      permissions: Role.get_masked_permissions(user.roles), # user.permissions
      roles: Enum.map(user.roles, &(&1.lookup))
    }
    # only append moderating, ban_expiration and malicious_score if present
    reply = if length(moderating = Map.get(user, :moderating)) != 0,
      do: Map.put(reply, :moderating, moderating),
      else: reply
    reply = if exp = Map.get(user, :ban_expiration),
      do: Map.put(reply, :ban_expiration, exp),
      else: reply
    reply = if ms = Map.get(user, :malicious_score),
      do: Map.put(reply, :malicious_score, ms),
      else: reply
    reply
  end
end
