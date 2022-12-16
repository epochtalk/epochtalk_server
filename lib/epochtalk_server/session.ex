defmodule EpochtalkServer.Session do
  @one_day_in_seconds 1 * 24 * 60 * 60
  @four_weeks_in_seconds 4 * 7 * @one_day_in_seconds

  @moduledoc """
  Manages `User` sessions in Redis. Used by Auth related `User` actions.
  """
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServer.Models.User

  @doc """
  Create session performs the following actions:
  * Sets user's session id, timestamp, ttl
  * Logs `User` in with Guardian to get token
  * Saves `User` session info to redis (avatar, roles, moderating, ban info, etc)
  * returns {:ok, user, token and conn}

  - TODO(boka): Handle expiration of redis sessions (this is handled in guardian but not redis)
  """
  @spec create(
          user :: User.t(),
          remember_me :: boolean,
          conn :: Plug.Conn.t()
        ) :: {:ok, user :: User.t(), encoded_token :: String.t(), conn :: Plug.Conn.t()}
  def create(%User{} = user, remember_me, conn) do
    datetime = NaiveDateTime.utc_now()
    decoded_token = %{user_id: user.id, timestamp: datetime}

    # set token expiration based on rememberMe
    guardian_ttl = if remember_me, do: {4, :weeks}, else: {1, :day}

    # sign user in and get encoded token
    conn = Guardian.Plug.sign_in(conn, decoded_token, %{}, ttl: guardian_ttl)
    encoded_token = Guardian.Plug.current_token(conn)
    # jti is a unique identifier for the jwt token, use it as session_id
    %{claims: %{"jti" => session_id}} = Guardian.peek(encoded_token)

    redis_ttl = if remember_me, do: @four_weeks_in_seconds, else: @one_day_in_seconds
    # save session
    case save(user, session_id, redis_ttl) do
      {:ok, _} -> {:ok, user, encoded_token, conn}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Gets all sessions for a specific `User`
  """
  @spec get_sessions(user :: User.t()) ::
          {:ok, user :: User.t(), sessions :: [String.t()]}
          | {:error, atom() | Redix.Error.t() | Redix.ConnectionError.t()}
  def get_sessions(%User{} = user) do
    # get session id's from redis under "user:{user_id}:sessions"
    session_key = generate_key(user.id, "sessions")

    case Redix.command(:redix, ["SMEMBERS", session_key]) do
      {:ok, sessions} -> {:ok, user, sessions}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Deletes a specific `User` session
  """
  @spec delete_session(
          user :: User.t(),
          session_id :: String.t()
        ) ::
          {:ok, user :: User.t()} | {:error, atom() | Redix.Error.t() | Redix.ConnectionError.t()}
  def delete_session(%User{} = user, session_id) do
    # delete session id from redis under "user:{user_id}:sessions"
    session_key = generate_key(user.id, "sessions")

    case Redix.command(:redix, ["SREM", session_key, session_id]) do
      {:ok, _} -> {:ok, user}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Deletes every session instance for the specified `User`
  """
  @spec delete_sessions(user :: User.t()) :: :ok
  def delete_sessions(%User{} = user) do
    # delete session id from redis under "user:{user_id}:sessions"
    session_key = generate_key(user.id, "sessions")

    case Redix.command(:redix, ["SPOP", session_key]) do
      {:ok, nil} -> :ok
      # repeat until redix returns nil
      _ -> delete_sessions(user)
    end
  end

  defp save(%User{} = user, session_id, ttl) do
    avatar = if is_nil(user.profile), do: nil, else: user.profile.avatar
    update_user_info(user.id, user.username, avatar, ttl)
    update_roles(user.id, user.roles, ttl)

    ban_info =
      if is_nil(user.ban_info), do: %{}, else: %{ban_expiration: user.ban_info.expiration}

    ban_info =
      if !is_nil(user.malicious_score) && user.malicious_score >= 1,
        do: Map.put(ban_info, :malicious_score, user.malicious_score),
        else: ban_info

    update_ban_info(user.id, ban_info, ttl)
    update_moderating(user.id, user.moderating, ttl)
    set_session(user.id, session_id)
  end

  # use default role
  defp update_roles(user_id, roles, ttl) when is_list(roles) do
    # save/replace roles to redis under "user:{user_id}:roles"
    role_lookups = roles |> Enum.map(& &1.lookup)
    role_key = generate_key(user_id, "roles")
    Redix.command(:redix, ["DEL", role_key])

    unless role_lookups == [],
      do: Enum.each(role_lookups, &Redix.command(:redix, ["SADD", role_key, &1]))

    # set expiration
    Redix.command(:redix, ["EXPIRE", role_key, ttl])
  end

  defp update_moderating(user_id, moderating, ttl) do
    # get list of board ids from user.moderating
    moderating = moderating |> Enum.map(& &1.board_id)
    # save/replace moderating boards to redis under "user:{user_id}:moderating"
    moderating_key = generate_key(user_id, "moderating")
    Redix.command(:redix, ["DEL", moderating_key])

    unless moderating == [],
      do: Enum.each(moderating, &Redix.command(:redix, ["SADD", moderating_key, &1]))

    # set expiration
    Redix.command(:redix, ["EXPIRE", moderating_key, ttl])
  end

  defp update_user_info(user_id, username, ttl) do
    user_key = generate_key(user_id, "user")
    # delete avatar from redis hash under "user:{user_id}"
    Redix.command(:redix, ["HDEL", user_key, "avatar"])
    # save username to redis hash under "user:{user_id}"
    Redix.command(:redix, ["HSET", user_key, "username", username])
    # set expiration
    Redix.command(:redix, ["EXPIRE", user_key, ttl])
  end

  defp update_user_info(user_id, username, avatar, ttl) when is_nil(avatar) or avatar == "" do
    update_user_info(user_id, username, ttl)
  end

  defp update_user_info(user_id, username, avatar, ttl) do
    # save username, avatar to redis hash under "user:{user_id}"
    user_key = generate_key(user_id, "user")
    Redix.command(:redix, ["HSET", user_key, "username", username, "avatar", avatar])
    # set expiration
    Redix.command(:redix, ["EXPIRE", user_key, ttl])
  end

  defp update_ban_info(user_id, ban_info, ttl) do
    # save/replace ban_expiration to redis under "user:{user_id}:baninfo"
    ban_key = generate_key(user_id, "baninfo")
    Redix.command(:redix, ["HDEL", ban_key, "ban_expiration", "malicious_score"])

    if ban_exp = Map.get(ban_info, :ban_expiration),
      do: Redix.command(:redix, ["HSET", ban_key, "ban_expiration", ban_exp])

    if malicious_score = Map.get(ban_info, :malicious_score),
      do: Redix.command(:redix, ["HSET", ban_key, "malicious_score", malicious_score])

    # set expiration
    Redix.command(:redix, ["EXPIRE", ban_key, ttl])
  end

  defp set_session(user_id, session_id) do
    # save session id to redis under "user:{user_id}:sessions"
    session_key = generate_key(user_id, "sessions")
    Redix.command(:redix, ["SADD", session_key, session_id])
  end

  defp generate_key(user_id, "user"), do: "user:#{user_id}"
  defp generate_key(user_id, type), do: "user:#{user_id}:#{type}"
end
