defmodule EpochtalkServer.Session do
  def save(db_user) do
    # TODO: return role lookups from db instead of entire roles

    # save username, avatar to redis hash under "user:{userId}"
    user_key = generate_key(db_user.id, "user")
    case db_user.avatar do
      "" -> Redix.command(:redix, ["HSET", user_key, "username", db_user.username])
      # set avatar if it's available
      _ -> Redix.command(:redix, ["HSET", user_key, "username", db_user.username, "avatar", db_user.avatar])
    end

    update_roles(db_user.id, db_user.roles)

    # save/replace ban_expiration to redis under "user:{userId}:baninfo"
    ban_key = generate_key(db_user.id, "baninfo")
    ban_info = %{}
    unless db_user.ban_expiration == nil do Map.add(ban_info, :expiration, db_user.ban_expiration) end
    if db_user.malicious_score >= 1 do Map.add(ban_info, :malicious_score, db_user.malicious_score) end
    Redix.command(:redix, ["DEL", ban_key])
    key_count = ban_info
    |> Map.keys
    |> List.length
    unless key_count == 0 do Redix.command(:redix, ["HSET", ban_key, "baninfo", ban_info]) end

    # save/replace moderating boards to redis under "user:{userId}:moderating"
    moderating_key = generate_key(db_user.id, "moderating")
    Redix.command(:redix, ["DEL", moderating_key])
    unless db_user.moderating == nil or db_user.moderating == [] do
      Redix.command(:redix, ["SADD", moderating_key, db_user.moderating])
    end

    # TODO: do this outside of here, need guardian token
    # -- or don't do it if we don't need this functionality
    # // save user-session to redis set under "user:{userId}:sessions"
    # .then(function() {
    #   var userSessionKey = 'user:' + dbUser.id + ':sessions';
    #   return redis.saddAsync(userSessionKey, decodedToken.sessionId);
    # })
    # .then(function() { return formatUserReply(token, dbUser); });
  end
  # use default role
  def update_roles(user_id, roles) when is_list(roles) do
    role_lookups = roles
    |> Enum.map(&(&1.lookup))
    role_key = generate_key(user_id, "roles")
    Redix.command(:redix, ["DEL", role_key])
    Redix.command(:redix, ["SADD", role_key, role_lookups])
  end
  def update_moderating do

  end
  def update_user_info do

  end
  def update_ban_info do

  end
  # save/replace roles to redis under "user:{userId}:roles"
  defp generate_key(user_id, "user"), do: "user:#{user_id}"
  defp generate_key(user_id, type), do: "user:#{user_id}:#{type}"
end
