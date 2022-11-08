defmodule EpochtalkServer.Auth.Guardian do
  use Guardian, otp_app: :epochtalk_server
  alias EpochtalkServer.Models.Role

  def subject_for_token(%{user_id: user_id}, _claims) do
    # You can use any value for the subject of your token but
    # it should be useful in retrieving the resource later, see
    # how it being used on `resource_from_claims/1` function.
    # A unique `id` is a good subject, a non-unique email address
    # is a poor subject.
    sub = Integer.to_string(user_id)
    {:ok, sub}
  end
  def subject_for_token(_, _), do: {:error, :reason_for_error}

  def resource_from_claims(%{"sub" => sub, "jti" => jti} = _claims) do
    # Here we'll look up our resource from the claims, the subject can be
    # found in the `"sub"` key. In above `subject_for_token/2` we returned
    # the resource id so here we'll rely on that to look it up.

    # extract user_id from subject
    user_id = String.to_integer(sub)
    # we are using the jti for sessions_id since it's unique
    session_id = jti
    # check if session is active in redis
    Redix.command!(:redix, ["SISMEMBER", "user:#{user_id}:sessions", session_id])
    |> case do
      0 ->
        # session is not active, return error
        {:error, "No session with id #{session_id}"}
      1 ->
        # session is active, populate data
        resource = %{
          id: user_id,
          session_id: session_id,
          username: Redix.command!(:redix, ["HGET", "user:#{user_id}", "username"]),
          avatar: Redix.command!(:redix, ["HGET", "user:#{user_id}", "avatar"]),
          roles: Redix.command!(:redix, ["SMEMBERS", "user:#{user_id}:roles"]) |> Role.by_lookup
        }
        # only append moderating, ban_expiration and malicious_score if present
        moderating = Redix.command!(:redix, ["SMEMBERS", "user:#{user_id}:moderating"])
        resource = if moderating && length(moderating) != 0,
          do: Map.put(resource, :moderating, moderating), else: resource

        ban_expiration = Redix.command!(:redix, ["HEXISTS", "user:#{user_id}:ban_info", "ban_expiration"])
        resource = if ban_expiration != 0,
          do: Map.put(resource, :ban_expiration, ban_expiration), else: resource

        malicious_score = Redix.command!(:redix, ["HEXISTS", "user:#{user_id}:ban_info", "malicious_score"])
        resource = if malicious_score != 0,
          do: Map.put(resource, :malicious_score, malicious_score), else: resource
        {:ok,  resource}
    end
  end
  def resource_from_claims(_claims), do: {:error, :reason_for_error}

  def after_encode_and_sign(resource, claims, token, _options) do
    with {:ok, _} <- Guardian.DB.after_encode_and_sign(resource, claims["typ"], claims, token) do
      {:ok, token}
    end
  end

  def on_verify(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_verify(claims, token) do
      {:ok, claims}
    end
  end

  def on_refresh({old_token, old_claims}, {new_token, new_claims}, _options) do
    with {:ok, _, _} <- Guardian.DB.on_refresh({old_token, old_claims}, {new_token, new_claims}) do
      {:ok, {old_token, old_claims}, {new_token, new_claims}}
    end
  end

  def on_revoke(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_revoke(claims, token) do
      {:ok, claims}
    end
  end
end
