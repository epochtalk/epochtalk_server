defmodule EpochtalkServer.Auth.Guardian do
  @moduledoc ~S"""
  Guardian provides a singular interface for authentication in Elixir applications
  that is `token` based.
  Tokens should be:
  * tamper proof
  * include a payload (claims)
  JWT tokens (the default) fit this description.
  When using Guardian, you'll need an implementation module.
  ```elixir
  defmodule MyApp.Guardian do
    use Guardian, otp_app: :my_app
    def subject_for_token(resource, _claims), do: {:ok, to_string(resource.id)}
    def resource_from_claims(claims) do
      find_me_a_resource(claims["sub"]) # {:ok, resource} or {:error, reason}
    end
  end
  ```
  This module is what you will use to interact with tokens in your application.
  When you `use` Guardian, the `:otp_app` option is required.
  Any other option provided will be merged with the configuration in the config
  files.
  The Guardian module contains some generated functions and some callbacks.
  ## Generated functions
  ### `default_token_type()`
  Overridable.
  Provides the default token type for the token - `"access"`
  Token types allow a developer to mark a token as having a particular purpose.
  Different types of tokens can then be used specifically in your app.
  Types may include (but are not limited to):
  * `"access"`
  * `"refresh"`
  Access tokens should be short lived and are used to access resources on your API.
  Refresh tokens should be longer lived and whose only purpose is to exchange
  for a shorter lived access token.
  To specify the type of token, use the `:token_type` option in
  the `encode_and_sign` function.
  Token type is encoded into the token in the `"typ"` field.
  Return - a string.
  ### `peek(token)`
  Inspect a tokens payload. Note that this function does no verification.
  Return - a map including the `:claims` key.
  ### `config()`, `config(key, default \\ nil)`
  Without argument `config` will return the full configuration Keyword list.
  When given a `key` and optionally a default, `config` will fetch a resolved value
  contained in the key.
  See `Guardian.Config.resolve_value/1`
  ### `encode_and_sign(resource, claims \\ %{}, opts \\ [])`
  Creates a signed token.
  Arguments:
  * `resource` - The resource to represent in the token (i.e. the user)
  * `claims` - Any custom claims that you want to use in your token
  * `opts` - Options for the token module and callbacks
  For more information on options see the documentation for your token module.
  ```elixir
  # Provide a token using the defaults including the default_token_type
  {:ok, token, full_claims} = MyApp.Guardian.encode_and_sign(user)
  # Provide a token including custom claims
  {:ok, token, full_claims} = MyApp.Guardian.encode_and_sign(user, %{some: "claim"})
  # Provide a token including custom claims and a different token type/ttl
  {:ok, token, full_claims} =
    MyApp.Guardian.encode_and_sign(user, %{some: "claim"}, token_type: "refresh", ttl: {4, :weeks})
  ```
  The `encode_and_sign` function calls a number of callbacks on
  your implementation module. See `Guardian.encode_and_sign/4`
  ### `decode_and_verify(token, claims_to_check \\ %{}, opts \\ [])`
  Decodes a token and verifies the claims are valid.
  Arguments:
  * `token` - The token to decode
  * `claims_to_check` - A map of the literal claims that should be matched. If
    any of the claims do not literally match verification fails.
  * `opts` - The options to pass to the token module and callbacks
  Callbacks:
  `decode_and_verify` calls a number of callbacks on your implementation module,
  See `Guardian.decode_and_verify/4`
  ```elixir
  # Decode and verify using the defaults
  {:ok, claims} = MyApp.Guardian.decode_and_verify(token)
  # Decode and verify with literal claims check.
  # If the claims in the token do not match those given verification will fail
  {:ok, claims} = MyApp.Guardian.decode_and_verify(token, %{match: "claim"})
  # Decode and verify with literal claims check and options.
  # Options are passed to your token module and callbacks
  {:ok, claims} = MyApp.Guardian.decode_and_verify(token, %{match: "claim"}, some: "secret")
  ```
  ### `revoke(token, opts \\ [])`
  Revoke a token.
  *Note:* this is entirely dependent on your token module and implementation
  callbacks.
  ```elixir
  {:ok, claims} = MyApp.Guardian.revoke(token, some: "option")
  ```
  ### refresh(token, opts \\ [])
  Refreshes the time on a token. This is used to re-issue a token with
  essentially the same claims but with a different expiry.
  Tokens are verified before performing the refresh to ensure
  only valid tokens may be refreshed.
  Arguments:
  * `token` - The old token to refresh
  * `opts` - Options to pass to the Implementation Module and callbacks
  Options:
  * `:ttl` - The new ttl. If not specified the default will be used.
  ```elixir
  {:ok, {old_token, old_claims}, {new_token, new_claims}} =
    MyApp.Guardian.refresh(old_token, ttl: {1, :hour})
  ```
  See `Guardian.refresh`
  ### `exchange(old_token, from_type, to_type, options)`
  Exchanges one token for another of a different type.
  Especially useful to trade in a `refresh` token for an `access` one.
  Tokens are verified before performing the exchange to ensure that
  only valid tokens may be exchanged.
  Arguments:
  * `old_token` - The existing token you wish to exchange.
  * `from_type` - The type the old token must be. Can be given a list of types.
  * `to_type` - The new type of token that you want back.
  * `options` - The options to pass to the token module and callbacks.
  Options:
  Options may be used by your token module or callbacks.
  * `ttl` - The ttl for the new token
  See `Guardian.exchange`

  **Note:** Copied from [Guardian Docs](https://github.com/ueberauth/guardian)
  """
  use Guardian, otp_app: :epochtalk_server
  alias EpochtalkServer.Session

  @doc """
  Fetches the subject for a token for the provided resource and claims
  The subject should be a short identifier that can be used to identify
  the resource.
  """
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

  @doc """
  Fetches the resource that is represented by claims.
  For JWT this would normally be found in the `sub` field.

  TODO(boka): refactor fetching of user session (L 161-202) into session.ex
  """
  def resource_from_claims(%{"sub" => sub, "jti" => jti} = _claims) do
    # Here we'll look up our resource from the claims, the subject can be
    # found in the `"sub"` key. In above `subject_for_token/2` we returned
    # the resource id so here we'll rely on that to look it up.

    # extract user_id from subject
    user_id = String.to_integer(sub)
    # we are using the jti for sessions_id since it's unique
    session_id = jti
    # check if session is active in redis
    Session.is_active_for_user_id(session_id, user_id)
    |> case do
      {:error, error} ->
        {:error, "Error finding resource from claims #{inspect(error)}"}
      false ->
        # session is not active, return error
        {:error, "No session with id #{session_id}"}

      true ->
        # session is active, populate data
        resource = %{
          id: user_id,
          session_id: session_id,
          username: Session.get_username_by_user_id(user_id),
          avatar: Session.get_avatar_by_user_id(user_id),
          roles: Session.get_roles_by_user_id(user_id)
        }

        # only append moderating, ban_expiration and malicious_score if present
        moderating = Session.get_moderating_by_user_id(user_id)

        resource =
          if moderating && length(moderating) != 0,
            do: Map.put(resource, :moderating, moderating),
            else: resource

        ban_expiration =
          Redix.command!(:redix, ["HEXISTS", "user:#{user_id}:ban_info", "ban_expiration"])

        resource =
          if ban_expiration != 0,
            do: Map.put(resource, :ban_expiration, ban_expiration),
            else: resource

        malicious_score =
          Redix.command!(:redix, ["HEXISTS", "user:#{user_id}:ban_info", "malicious_score"])

        resource =
          if malicious_score != 0,
            do: Map.put(resource, :malicious_score, malicious_score),
            else: resource

        {:ok, resource}
    end
  end

  def resource_from_claims(_claims), do: {:error, :reason_for_error}

  @doc """
  An optional callback invoked after the token has been generated
  and signed.
  """
  def after_encode_and_sign(resource, claims, token, _options) do
    with {:ok, _} <- Guardian.DB.after_encode_and_sign(resource, claims["typ"], claims, token) do
      {:ok, token}
    end
  end

  @doc """
  An optional callback invoked after the claims have been validated.
  """
  def on_verify(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_verify(claims, token) do
      {:ok, claims}
    end
  end

  @doc """
  An optional callback invoked when a token is refreshed.
  """
  def on_refresh({old_token, old_claims}, {new_token, new_claims}, _options) do
    with {:ok, _, _} <- Guardian.DB.on_refresh({old_token, old_claims}, {new_token, new_claims}) do
      {:ok, {old_token, old_claims}, {new_token, new_claims}}
    end
  end

  @doc """
  An optional callback invoked when a token is revoked.
  """
  def on_revoke(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_revoke(claims, token) do
      {:ok, claims}
    end
  end
end
