defmodule EpochtalkServer.Session do
  @one_day_in_seconds 1 * 24 * 60 * 60
  @four_weeks_in_seconds 4 * 7 * @one_day_in_seconds

  @moduledoc """
  Manages `User` sessions in Redis. Used by Auth related `User` actions.
  """
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Role

  @doc """
  Create session performs the following actions:
  * Sets user's session id, timestamp, ttl
  * Logs `User` in with Guardian to get token
  * Saves `User` session info to redis (avatar, roles, moderating, ban info, etc)
  * returns {:ok, user, token and conn}
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
  Update session performs the following actions for active session:
  * Saves `User` session info to redis (avatar, roles, moderating, ban info, etc)
  * returns {:ok, user}

  DOES NOT change:
  * User's session id, timestamp, ttl
  * Guardian token
  """
  @spec update(user_id :: non_neg_integer) :: {:ok, user :: User.t()}
  def update(user_id) do
    user = User.by_id(user_id)
    avatar = if is_nil(user.profile), do: nil, else: user.profile.avatar
    update_user_info(user.id, user.username, avatar: avatar)
    update_roles(user.id, user.roles)
    update_moderating(user.id, user.moderating)
    {:ok, user}
  end

  @doc """
  Get the resource for a specified user_id and session_id if available
  Otherwise, return an error
  """
  @spec get_resource(user_id :: non_neg_integer, session_id :: String.t()) ::
          {:ok, resource :: map()}
          | {:error, reason :: String.t() | Redix.Error.t() | Redix.ConnectionError.t()}
  def get_resource(user_id, session_id) do
    # check if session is active in redis
    is_active_for_user_id(session_id, user_id)
    |> case do
      {:error, error} ->
        {:error, "Error finding resource from claims #{inspect(error)}"}

      false ->
        # session is not active, return error
        {:error, "No session for user_id #{user_id} with id #{session_id}"}

      true ->
        user_key = generate_key(user_id, "user")
        username = Redix.command!(:redix, ["HGET", user_key, "username"])
        avatar = Redix.command!(:redix, ["HGET", user_key, "avatar"])
        role_key = generate_key(user_id, "roles")
        roles = Redix.command!(:redix, ["SMEMBERS", role_key]) |> Role.by_lookup()

        # session is active, populate data
        resource = %{
          id: user_id,
          session_id: session_id,
          username: username,
          avatar: avatar,
          roles: roles
        }

        # only append moderating, ban_expiration and malicious_score if present
        moderating_key = generate_key(user_id, "moderating")
        moderating = Redix.command!(:redix, ["SMEMBERS", moderating_key])

        resource =
          if moderating && length(moderating) != 0,
            do: Map.put(resource, :moderating, moderating),
            else: resource

        ban_key = generate_key(user_id, "baninfo")
        ban_expiration = Redix.command!(:redix, ["HEXISTS", ban_key, "ban_expiration"])

        resource =
          if ban_expiration != 0,
            do: Map.put(resource, :ban_expiration, ban_expiration),
            else: resource

        malicious_score = Redix.command!(:redix, ["HEXISTS", ban_key, "malicious_score"])

        resource =
          if malicious_score != 0,
            do: Map.put(resource, :malicious_score, malicious_score),
            else: resource

        {:ok, resource}
    end
  end

  @doc """
  Gets all session ids for a specific user_id
  """
  @spec get_sessions(user_id :: non_neg_integer) ::
          {:ok, sessions_ids :: [String.t()]}
          | {:error, atom() | Redix.Error.t() | Redix.ConnectionError.t()}
  def get_sessions(user_id) do
    # get session id's from redis under "user:{user_id}:sessions"
    session_key = generate_key(user_id, "sessions")

    Redix.command(:redix, ["ZRANGE", session_key, 0, -1])
  end

  defp is_active_for_user_id(session_id, user_id) do
    session_key = generate_key(user_id, "sessions")
    # check ZSCORE for user_id:session_id pair
    # returns score if it is a member of the set
    # returns nil if not a member
    case Redix.command(:redix, ["ZSCORE", session_key, session_id]) do
      {:error, error} -> {:error, error}
      {:ok, nil} -> false
      {:ok, _score} -> true
    end
  end

  @doc """
  Deletes the session specified in conn
  """
  @spec delete(conn :: Plug.Conn.t()) ::
          {:ok, conn :: Plug.Conn.t()}
          | {:error, atom() | Redix.Error.t() | Redix.ConnectionError.t()}
  def delete(conn) do
    # get user from guardian resource
    %{id: user_id} = Guardian.Plug.current_resource(conn)
    # get session_id from jti in jwt token
    %{claims: %{"jti" => session_id}} =
      Guardian.Plug.current_token(conn)
      |> Guardian.peek()

    # delete session id from redis under "user:{user_id}:sessions"
    session_key = generate_key(user_id, "sessions")

    case Redix.command(:redix, ["ZREM", session_key, session_id]) do
      {:ok, _} ->
        # sign user out
        conn = Guardian.Plug.sign_out(conn)
        {:ok, conn}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Deletes every session instance for the specified `User`
  """
  @spec delete_sessions(user :: User.t()) :: {:ok, non_neg_integer} | Redix.ConnectionError.t()
  def delete_sessions(%User{} = user) do
    # delete session id from redis under "user:{user_id}:sessions"
    session_key = generate_key(user.id, "sessions")
    Redix.command(:redix, ["DEL", session_key])
  end

  defp save(%User{} = user, session_id, ttl) do
    avatar = if is_nil(user.profile), do: nil, else: user.profile.avatar
    update_user_info(user.id, user.username, avatar: avatar, ttl: ttl)
    update_roles(user.id, user.roles, ttl)

    ban_info =
      if is_nil(user.ban_info), do: %{}, else: %{ban_expiration: user.ban_info.expiration}

    ban_info =
      if !is_nil(user.malicious_score) && user.malicious_score >= 1,
        do: Map.put(ban_info, :malicious_score, user.malicious_score),
        else: ban_info

    update_ban_info(user.id, ban_info, ttl)
    update_moderating(user.id, user.moderating, ttl)
    add_session(user.id, session_id, ttl)
  end

  defp update_roles(user_id, roles, ttl \\ nil) when is_list(roles) do
    # save/replace roles to redis under "user:{user_id}:roles"
    role_lookups = roles |> Enum.map(& &1.lookup)
    role_key = generate_key(user_id, "roles")
    # get current TTL
    {:ok, old_ttl} = Redix.command(:redix, ["TTL", role_key])
    Redix.command(:redix, ["DEL", role_key])

    unless role_lookups == [],
      do: Enum.each(role_lookups, &Redix.command(:redix, ["SADD", role_key, &1]))

    # if ttl is provided
    if ttl do
      # maybe extend ttl
      maybe_extend_ttl(role_key, ttl, old_ttl)
    else
      # otherwise, re-set old_ttl
      maybe_extend_ttl(role_key, old_ttl)
    end
  end

  defp update_moderating(user_id, moderating, ttl \\ nil) do
    # get list of board ids from user.moderating
    moderating = moderating |> Enum.map(& &1.board_id)
    # save/replace moderating boards to redis under "user:{user_id}:moderating"
    moderating_key = generate_key(user_id, "moderating")
    # get current TTL
    {:ok, old_ttl} = Redix.command(:redix, ["TTL", moderating_key])
    Redix.command(:redix, ["DEL", moderating_key])

    unless moderating == [],
      do: Enum.each(moderating, &Redix.command(:redix, ["SADD", moderating_key, &1]))

    # if ttl is provided
    if ttl do
      # maybe extend ttl
      maybe_extend_ttl(moderating_key, ttl, old_ttl)
    else
      # otherwise, re-set old_ttl
      maybe_extend_ttl(moderating_key, old_ttl)
    end
  end

  defp update_user_info(user_id, username, opts \\ []) do
    # save user info to redis hash under "user:{user_id}"
    user_key = generate_key(user_id, "user")
    avatar = opts[:avatar]
    ttl = opts[:ttl]
    # if avatar not present
    if is_nil(avatar) do
      Redix.command(:redix, ["HDEL", user_key, "avatar"])
      # delete avatar from redis hash
      Redix.command(:redix, ["HDEL", user_key, "avatar"])
      # save username to redis hash
      Redix.command(:redix, ["HSET", user_key, "username", username])
    else
      # save username and avatar to redis hash
      user_key = generate_key(user_id, "user")
      Redix.command(:redix, ["HSET", user_key, "username", username, "avatar", avatar])
    end

    # if ttl is provided
    if ttl do
      # maybe extend ttl
      maybe_extend_ttl(user_key, ttl)
    end
  end

  defp update_ban_info(user_id, ban_info, ttl) do
    # save/replace ban_expiration to redis under "user:{user_id}:baninfo"
    ban_key = generate_key(user_id, "baninfo")
    # get current TTL
    {:ok, old_ttl} = Redix.command(:redix, ["TTL", ban_key])
    Redix.command(:redix, ["HDEL", ban_key, "ban_expiration", "malicious_score"])

    if ban_exp = Map.get(ban_info, :ban_expiration),
      do: Redix.command(:redix, ["HSET", ban_key, "ban_expiration", ban_exp])

    if malicious_score = Map.get(ban_info, :malicious_score),
      do: Redix.command(:redix, ["HSET", ban_key, "malicious_score", malicious_score])

    # set ttl
    maybe_extend_ttl(ban_key, ttl, old_ttl)
  end

  # session storage uses "pseudo-expiry" (via redis sorted-set score)
  # these rules ensure that session storage will not grow indefinitely:
  #
  # on every new session add,
  #   clean (delete) expired sessions by expiry
  #   add the new session, with expiry
  #   ttl expiry for this key will delete all sessions in the set
  defp add_session(user_id, session_id, ttl) do
    # save session id to redis under "user:{user_id}:sessions"
    session_key = generate_key(user_id, "sessions")
    # delete expired sessions
    delete_expired_sessions(session_key)
    # intended unix expiration of this session
    unix_expiration = current_time() + ttl

    # add new session, noting unix expiration
    result = Redix.command(:redix, ["ZADD", session_key, unix_expiration, session_id])

    # set ttl
    maybe_extend_ttl(session_key, ttl)
    result
  end

  # delete expired sessions by expiration (sorted set score)
  defp delete_expired_sessions(session_key) do
    Redix.command(:redix, ["ZREMRANGEBYSCORE", session_key, "-inf", current_time()])
  end

  # current unix time (default :seconds)
  defp current_time() do
    DateTime.utc_now() |> DateTime.to_unix()
  end

  defp generate_key(user_id, "user"), do: "user:#{user_id}"
  defp generate_key(user_id, type), do: "user:#{user_id}:#{type}"

  defp maybe_extend_ttl(key, ttl) do
    # use new/old extend, where new == old
    maybe_extend_ttl(key, ttl, ttl)
  end

  defp maybe_extend_ttl(key, new_ttl, old_ttl) do
    if old_ttl > -1 do
      # re-set old expiry only if old expiry was valid and key has no expiry
      Redix.command(:redix, ["EXPIRE", key, old_ttl, "NX"])
    else
      # if old expiry was invalid, set new expiry only if key has no expiry
      Redix.command(:redix, ["EXPIRE", key, new_ttl, "NX"])
    end

    # set expiry only if new expiry is greater than current (GT)
    Redix.command(:redix, ["EXPIRE", key, new_ttl, "GT"])
  end
end
