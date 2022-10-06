defmodule EpochtalkServer.Session do
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServer.Models.User

  # set user session id, timestamp, ttl
  # log user in with Guardian to get token
  # save user session info to redis
  # returns {:ok, user, token and conn}
  def create(%User{} = user, remember_me, conn) do
    datetime = NaiveDateTime.utc_now
    session_id = UUID.uuid1()
    decoded_token = %{ user_id: user.id, session_id: session_id, timestamp: datetime }

    # set token expiration based on rememberMe
    ttl = if remember_me, do: {4, :weeks}, else: {1, :day}

    # sign user in and get encoded token
    conn = Guardian.Plug.sign_in(conn, decoded_token, %{}, ttl: ttl)
    encoded_token = Guardian.Plug.current_token(conn)

    # save session
    save(user, session_id)
    # TODO(akinsey): error handling
    # return user with token
    {:ok, user, encoded_token, conn}
  end
  defp save(%User{} = user, session_id) do
    # TODO: return role lookups from db instead of entire roles
    avatar = if is_nil(user.profile), do: nil, else: user.profile.avatar
    update_user_info(user.id, user.username, avatar)
    update_roles(user.id, user.roles)
    ban_info = if is_nil(user.ban_info), do: %{}, else: %{ ban_expiration: user.ban_info.expiration }
    ban_info = if !is_nil(user.malicious_score) && user.malicious_score >= 1, do: Map.put(ban_info, :malicious_score, user.malicious_score), else: ban_info
    update_ban_info(user.id, ban_info)
    update_moderating(user.id, user.moderating)
    set_session(user.id, session_id)
  end
  # use default role
  def update_roles(user_id, roles) when is_list(roles) do
    # save/replace roles to redis under "user:{user_id}:roles"
    role_lookups = roles |> Enum.map(&(&1.lookup))
    role_key = generate_key(user_id, "roles")
    Redix.command(:redix, ["DEL", role_key])
    unless role_lookups == nil or role_lookups == [], do:
      Enum.each(role_lookups, &Redix.command(:redix, ["SADD", role_key, &1]))
  end
  def update_moderating(user_id, moderating) do
    # get list of board ids from user.moderating
    moderating = moderating |> Enum.map(&(&1.board_id))
    # save/replace moderating boards to redis under "user:{user_id}:moderating"
    moderating_key = generate_key(user_id, "moderating")
    Redix.command(:redix, ["DEL", moderating_key])
    unless moderating == nil or moderating == [], do:
      Enum.each(moderating, &Redix.command(:redix, ["SADD", moderating_key, &1]))
  end
  def update_user_info(user_id, username) do
    user_key = generate_key(user_id, "user")
    # delete avatar from redis hash under "user:{user_id}"
    Redix.command(:redix, ["HDEL", user_key, "avatar"])
    # save username to redis hash under "user:{user_id}"
    Redix.command(:redix, ["HSET", user_key, "username", username])
  end
  def update_user_info(user_id, username, avatar) when is_nil(avatar) or avatar == "" do
    update_user_info(user_id, username)
  end
  def update_user_info(user_id, username, avatar) do
    # save username, avatar to redis hash under "user:{user_id}"
    user_key = generate_key(user_id, "user")
    Redix.command(:redix, ["HSET", user_key, "username", username, "avatar", avatar])
  end
  def update_ban_info(user_id, ban_info) do
    # save/replace ban_expiration to redis under "user:{user_id}:baninfo"
    ban_key = generate_key(user_id, "baninfo")
    Redix.command(:redix, ["HDEL", ban_key, "ban_expiration", "malicious_score"])
    if ban_exp = Map.get(ban_info, :ban_expiration), do: Redix.command(:redix, ["HSET", ban_key, "ban_expiration", ban_exp])
    if malicious_score = Map.get(ban_info, :malicious_score), do: Redix.command(:redix, ["HSET", ban_key, "malicious_score", malicious_score])
  end
  defp set_session(user_id, session_id) do
    # save session id to redis under "user:{user_id}:sessions"
    session_key = generate_key(user_id, "sessions")
    Redix.command(:redix, ["SADD", session_key, session_id])
  end
  defp get_sessions(user_id) do
    # get session id's from redis under "user:{user_id}:sessions"
    session_key = generate_key(user_id, "sessions")
    Redix.command(:redix, ["SMEMBERS", session_key])
  end
  # TODO: invalidate token
  defp delete_session(user_id, session_id) do
    # delete session id from redis under "user:{user_id}:sessions"
    session_key = generate_key(user_id, "sessions")
    Redix.command(:redix, ["SREM", session_key, session_id])
  end
  defp delete_sessions(user_id, session_id) do
    # delete session id from redis under "user:{user_id}:sessions"
    session_key = generate_key(user_id, "sessions")
    Redix.command(:redix, ["SPOP", session_key, session_id])
    # repeat until redix returns nil
    |> unless do delete_sessions(user_id, session_id) end
  end
  defp generate_key(user_id, "user"), do: "user:#{user_id}"
  defp generate_key(user_id, type), do: "user:#{user_id}:#{type}"
end
