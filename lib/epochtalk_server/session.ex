defmodule EpochtalkServer.Session do
  def save(db_user) do
    # TODO: return role lookups from db instead of entire roles
    update_user_info(db_user.id, db_user.username, db_user.avatar)
    update_roles(db_user.id, db_user.roles)

    # save/replace ban_expiration to redis under "user:{user_id}:baninfo"
    ban_key = generate_key(db_user.id, "baninfo")
    ban_info = %{}
    unless db_user.ban_expiration == nil do Map.add(ban_info, :expiration, db_user.ban_expiration) end
    if db_user.malicious_score >= 1 do Map.add(ban_info, :malicious_score, db_user.malicious_score) end
    Redix.command(:redix, ["DEL", ban_key])
    key_count = ban_info
    |> Map.keys
    |> List.length
    unless key_count == 0 do Redix.command(:redix, ["HSET", ban_key, "baninfo", ban_info]) end

    update_moderating(db_user.id, db_user.moderating)
    # TODO: do this outside of here, need guardian token
    # -- or don't do it if we don't need this functionality
    # // save user-session to redis set under "user:{user_id}:sessions"
    # .then(function() {
    #   var userSessionKey = 'user:' + dbUser.id + ':sessions';
    #   return redis.saddAsync(userSessionKey, decodedToken.sessionId);
    # })
    # .then(function() { return formatUserReply(token, dbUser); });
  end
  # use default role
  def update_roles(user_id, roles) when is_list(roles) do
    # save/replace roles to redis under "user:{user_id}:roles"
    role_lookups = roles
    |> Enum.map(&(&1.lookup))
    role_key = generate_key(user_id, "roles")
    Redix.command(:redix, ["DEL", role_key])
    Redix.command(:redix, ["SADD", role_key, role_lookups])
  end
  def update_moderating(user_id, moderating) do
    # save/replace moderating boards to redis under "user:{user_id}:moderating"
    moderating_key = generate_key(user_id, "moderating")
    Redix.command(:redix, ["DEL", moderating_key])
    unless moderating == nil or moderating == [] do
      Redix.command(:redix, ["SADD", moderating_key, moderating])
    end
  end
  def update_user_info(user_id, username) do
    user_key = generate_key(db_user.id, "user")
    # delete avatar from redis hash under "user:{user_id}"
    Redis.command(:redis, ["HDEL", user_key, "avatar"])
    # save username to redis hash under "user:{user_id}"
    Redix.command(:redix, ["HSET", user_key, "username", db_user.username])
  end
  def update_user_info(user_id, username, avatar) when is_nil(avatar) or avatar == "" do
    update_user_info(user_id, username)
  end
  def update_user_info(user_id, username, avatar) do
    # save username, avatar to redis hash under "user:{user_id}"
    user_key = generate_key(db_user.id, "user")
    Redix.command(:redix, ["HSET", user_key, "username", db_user.username, "avatar", db_user.avatar])
  end
  def update_ban_info do

  end
  defp generate_key(user_id, "user"), do: "user:#{user_id}"
  defp generate_key(user_id, type), do: "user:#{user_id}:#{type}"
end
