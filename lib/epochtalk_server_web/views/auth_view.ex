defmodule EpochtalkServerWeb.AuthView do
  use EpochtalkServerWeb, :view
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.User

  def render("search.json", %{found: found}), do: %{found: found}

  def render("logout.json", _data), do: true

  def render("user.json", %{user: user, token: token}), do: format_user_reply(user, token)


  # Format reply from User ecto schema
  defp format_user_reply(%User{} = user, token) do
    avatar = if !!user.profile, do: user.profile.avatar, else: nil
    permissions = Role.get_masked_permissions(Enum.map(user.roles, &(&1.role)))
    roles = Enum.map(user.roles, &(&1.role.lookup))
    moderating = if length(user.moderating) != 0, do: Enum.map(user.moderating, &(&1.board_id)), else: nil
    ban_expiration = if !!user.ban_info, do: user.ban_info.expiration, else: nil
    malicious_score = if !!user.malicious_score, do: user.malicious_score, else: nil
    format_user_reply(user, token, {avatar, permissions, roles, moderating, ban_expiration, malicious_score})
  end
  defp format_user_reply(user, token) do
    avatar = Map.get(user, :avatar)
    permissions = Role.get_masked_permissions(user.roles)
    roles = Enum.map(user.roles, &(&1.lookup))
    moderating = if Map.get(user, :moderating) && length(user.moderating) != 0, do: user.moderating, else: nil
    ban_expiration = Map.get(user, :ban_expiration)
    malicious_score = Map.get(user, :malicious_score)
    format_user_reply(user, token, {avatar, permissions, roles, moderating, ban_expiration, malicious_score})
  end

  defp format_user_reply(user, token, {avatar, permissions, roles, moderating, ban_expiration, malicious_score}) do
    reply = %{
      token: token,
      id: user.id,
      username: user.username,
      permissions: permissions,
      roles: roles
    }
    # only append avatar, moderating, ban_expiration and malicious_score if present
    reply = if avatar, do: Map.put(reply, :avatar, avatar), else: reply
    reply = if moderating, do: Map.put(reply, :moderating, moderating), else: reply
    reply = if ban_expiration, do: Map.put(reply, :ban_expiration, ban_expiration), else: reply
    reply = if malicious_score, do: Map.put(reply, :malicious_score, malicious_score), else: reply
    reply
  end

  # defp format_user_reply(user, token) do
  #   reply = %{
  #     token: token,
  #     id: user.id,
  #     username: user.username,
  #     avatar: Map.get(user, :avatar), # user.avatar
  #     permissions: Role.get_masked_permissions(user.roles), # user.permissions
  #     roles: Enum.map(user.roles, &(&1.lookup))
  #   }
  #   # only append moderating, ban_expiration and malicious_score if present
  #   moderating = Map.get(user, :moderating)
  #   reply = if !is_nil(moderating) && length(moderating) != 0,
  #     do: Map.put(reply, :moderating, moderating),
  #     else: reply
  #   reply = if exp = Map.get(user, :ban_expiration),
  #     do: Map.put(reply, :ban_expiration, exp),
  #     else: reply
  #   reply = if ms = Map.get(user, :malicious_score),
  #     do: Map.put(reply, :malicious_score, ms),
  #     else: reply
  #   reply
  # end
end
