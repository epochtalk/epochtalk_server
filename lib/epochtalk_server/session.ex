defmodule EpochtalkServer.Session do
  def save(db_user) do
    # replace db_user role with role lookups
    # |> Map.put(:role, Enum.map(db_user.roles, &(&1.lookup))
    # actually, just assume role lookups are there
    # TODO: return role lookups from db instead of entire roles

    # set default role if necessary
    roles = db_user.roles
    |> List.length
    |> case do
      0 -> ['user']
      _ -> db_user.roles
    end
    db_user = Map.put(db_user, :roles, roles)

    # save username, avatar to redis hash under "user:{userId}"
    user_key = "user:#{db_user.id}"
    case db_user.avatar do
      "" -> Redix.command(:redix, ["HSET", user_key, "username", db_user.username])
      # set avatar if it's available
      _ -> Redix.command(:redix, ["HSET", user_key, "username", db_user.username, "avatar", db_user.avatar])
    end

    # save/replace roles to redis under "user:{userId}:roles"
    role_key = "user:#{db_user.id}:roles"
    Redix.command(:redix, ["DEL", role_key])
    Redix.command(:redix, ["SADD", role_key, db_user.roles])

    # save/replace ban_expiration to redis under "user:{userId}:baninfo"
    ban_key = "user:#{db_user.id}:baninfo"
    ban_info = %{}
    unless db_user.ban_expiration == nil do Map.add(ban_info, :expiration, db_user.ban_expiration) end
    if db_user.malicious_score >= 1 do Map.add(ban_info, :malicious_score, db_user.malicious_score) end
    Redix.command(:redix, ["DEL", ban_key])
    key_count = ban_info
    |> Map.keys
    |> List.length
    unless key_count == 0 do Redix.command(:redix, ["HSET", ban_key, "baninfo", ban_info]) end

    # save/replace moderating boards to redis under "user:{userId}:moderating"
    moderating_key = "user:#{db_user.id}:moderating"
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
  def update_roles do

  end
  def update_moderating do

  end
  def update_user_info do

  end
  def update_ban_info do

  end
end
