defmodule EpochtalkServerWeb.Controllers.User do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `User` related API requests
  """
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.UserActivity
  alias EpochtalkServer.Models.Ban
  alias EpochtalkServer.Models.MetricRankMap
  alias EpochtalkServer.Models.Rank
  alias EpochtalkServer.Models.Invitation
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServer.Session
  alias EpochtalkServer.Mailer
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.CustomErrors.InvalidPayload
  alias EpochtalkServerWeb.Helpers.ACL
  alias EpochtalkServerWeb.Helpers.Validate
  alias EpochtalkServer.SmfQuery

  plug :check_proxy when action in [:find]

  @doc """
  Used to check if a username has already been taken
  """
  def username(conn, %{"username" => username}),
    do: render(conn, :data, data: %{found: User.with_username_exists?(username)})

  @doc """
  Used to check if an email has already been taken
  """
  def email(conn, %{"email" => email}),
    do: render(conn, :data, data: %{found: User.with_email_exists?(email)})

  @doc """
  Registers a new `User`
  """
  def register(conn, %{"username" => _, "email" => _, "password" => _} = attrs) do
    config = Application.get_env(:epochtalk_server, :frontend_config)
    # check auth
    with {:auth, false} <- {:auth, Guardian.Plug.authenticated?(conn)},
         {:invite_only, false} <- {:invite_only, !!config[:invite_only]},
         {:verify_registration, false} <- {:verify_registration, !!config[:verify_registration]},
         # create user
         {:ok, user} <- User.create(attrs),
         # delete invitation
         {_count, nil} <- Invitation.delete(user.email),
         # ban if malicious
         {:ok, user} <- User.handle_malicious_user(user, conn.remote_ip),
         # create session
         {:ok, user, token, conn} <- Session.create(user, false, conn) do
      render(conn, :user, %{user: user, token: token})
    else
      # user already authenticated
      {:auth, true} ->
        ErrorHelpers.render_json_error(conn, 400, "Cannot register a new account while logged in")

      # forum is set to invite only
      {:invite_only, true} ->
        ErrorHelpers.render_json_error(conn, 423, "Registration is closed, forum is invite only")

      # verify registration is on, run register_with_verify instead
      {:verify_registration, true} ->
        register_with_verify(conn, attrs)

      # error banning in handle_malicious_user
      {:error, :ban_error} ->
        ErrorHelpers.render_json_error(
          conn,
          500,
          "There was an error banning malicious user, upon login"
        )

      # error in user.create
      {:error, data} ->
        ErrorHelpers.render_json_error(conn, 400, data)

      # Catch all for any other errors
      _ ->
        ErrorHelpers.render_json_error(conn, 500, "There was an issue registering")
    end
  end

  def register(_conn, _attrs), do: raise(InvalidPayload)

  defp register_with_verify(conn, attrs) do
    # add confirmation token
    attrs =
      attrs |> Map.put("confirmation_token", :crypto.strong_rand_bytes(16) |> Base.encode16())

    # create user
    with {:ok, user} <- User.create(attrs),
         # delete invitation
         {_count, nil} <- Invitation.delete(user.email),
         # send confirm account email
         {:ok, _email} <- Mailer.send_confirm_account(user) do
      render(conn, :register_with_verify, user: user)
    else
      # error email failed to send
      {:error, :not_delivered} ->
        ErrorHelpers.render_json_error(
          conn,
          500,
          "Sending of account confirmation email failed, mailer is not properly configured."
        )

      # error in user.create
      {:error, data} ->
        ErrorHelpers.render_json_error(conn, 400, data)

      # Catch all for any other errors
      _ ->
        ErrorHelpers.render_json_error(conn, 500, "There was an issue registering")
    end
  end

  @doc """
  Confirms a newly registered `User`. Used when `:epochtalk_server[:frontend_config][:verify_registration]`
  configuration is set to `true`
  """
  def confirm(conn, %{"username" => username, "token" => token}) do
    # create user
    with {:ok, user} <- User.by_username(username),
         # submit confirmation token for checking and update user if confirmed
         {:token_valid, true} <- {:token_valid, User.maybe_confirm?(user, token)},
         # ban if malicious
         {:ok, user} <- User.handle_malicious_user(user, conn.remote_ip),
         # create session
         {:ok, user, token, conn} <- Session.create(user, false, conn) do
      render(conn, :user, %{user: user, token: token})
    else
      {:error, :user_not_found} ->
        ErrorHelpers.render_json_error(conn, 400, "Confirmation error, account not found")

      {:token_valid, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Account confirmation error, invalid token")

      {:error, :ban_error} ->
        ErrorHelpers.render_json_error(
          conn,
          500,
          "There was an error banning malicious user, upon confirming account"
        )
    end
  end

  def confirm(_conn, _attrs), do: raise(InvalidPayload)

  @doc """
  Finds a `User`.
  """
  def find(conn, %{"username" => username}) do
    with {:ok, user} <- User.by_username(username),
         activity <- UserActivity.get_by_user_id(user.id),
         metric_rank_maps <- MetricRankMap.all_merged(),
         ranks <- Rank.all(),
         authed_user <- Guardian.Plug.current_resource(conn),
         # Authorizations Checks
         :ok <- ACL.allow!(conn, "users.find"),
         {:user_not_deleted, user_not_deleted} <-
           {:user_not_deleted, if(user.id || !user.deleted, do: true, else: false)},
         {:has_deleted_override, has_deleted_override} <-
           {:has_deleted_override, ACL.has_permission(conn, "users.find.bypass.viewDeleted")},
         {:view_deleted, true} <- {:view_deleted, user_not_deleted || has_deleted_override},
         {:view_as_self, view_as_self} <-
           {:view_as_self, authed_user && authed_user.id == user.id},
         {:view_as_admin, view_as_admin} <-
           {:view_as_admin, ACL.has_permission(conn, "users.find.bypass.viewMoreInfo")},
         {:show_hidden, show_hidden} <- {:show_hidden, view_as_self || view_as_admin} do
      render(conn, :find, %{
        user: user,
        activity: activity,
        metric_rank_maps: metric_rank_maps,
        ranks: ranks,
        show_hidden: show_hidden
      })
    else
      {:error, :user_not_found} ->
        ErrorHelpers.render_json_error(conn, 400, "Account not found")

      {:view_deleted, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Account not found")
    end
  end

  def find(_conn, _attrs), do: raise(InvalidPayload)

  @doc """
  Authenticates currently logged in `User`
  """
  def authenticate(conn, _attrs) do
    token = Guardian.Plug.current_token(conn)
    user = Guardian.Plug.current_resource(conn)
    render(conn, :user, %{user: user, token: token})
  end

  @doc """
  Logs out the logged in `User`
  """
  def logout(conn, _attrs) do
    with user <- Guardian.Plug.current_resource(conn),
         token <- Guardian.Plug.current_token(conn),
         {:ok, conn} <- Session.delete(conn) do
      EpochtalkServerWeb.Endpoint.broadcast("user:#{user.id}", "logout", %{token: token})
      render(conn, :data, data: %{success: true})
    else
      {:error, error} -> ErrorHelpers.render_json_error(conn, 500, error)
    end
  end

  @doc """
  Logs in an existing `User`
  """
  def login(conn, attrs) when not is_map_key(attrs, "rememberMe"),
    do: login(conn, Map.put(attrs, "rememberMe", false))

  def login(
        conn,
        %{"username" => username, "password" => password} = attrs
      ) do
    with remember_me <- Validate.cast(attrs, "rememberMe", :boolean),
         {:auth, false} <- {:auth, Guardian.Plug.authenticated?(conn)},
         {:ok, user} <- User.by_username(username),
         {:not_confirmed, false} <- {:not_confirmed, !!Map.get(user, :confirmation_token)},
         {:missing_passhash, true} <- {:missing_passhash, !!Map.get(user, :passhash)},
         {:valid_password, true} <- {:valid_password, User.valid_password?(user, password)},
         {:ok, user} <- Ban.unban(user),
         {:ok, user, token, conn} <- Session.create(user, remember_me, conn) do
      render(conn, :user, %{user: user, token: token})
    else
      {:auth, true} ->
        ErrorHelpers.render_json_error(conn, 400, "Already logged in")

      {:error, :user_not_found} ->
        ErrorHelpers.render_json_error(conn, 400, "Invalid credentials")

      {:not_confirmed, true} ->
        ErrorHelpers.render_json_error(conn, 400, "User account not confirmed")

      {:missing_passhash, false} ->
        ErrorHelpers.render_json_error(
          conn,
          403,
          "User account migration not complete, please reset password"
        )

      {:valid_password, false} ->
        ErrorHelpers.render_json_error(conn, 400, "Invalid credentials")

      {:error, :unban_error} ->
        ErrorHelpers.render_json_error(conn, 500, "There was an issue unbanning user, upon login")
    end
  end

  def login(_conn, _attrs), do: raise(InvalidPayload)

  ## === Private Helper Functions ===

  defp check_proxy(conn, _) do
    case conn.private.phoenix_action do
      :find ->
        conn
        |> proxy_find(conn.params)
        |> halt()

      _ ->
        conn
    end
  end

  defp proxy_find(conn, attrs) do
    with user <- SmfQuery.find_user(attrs["id"]) do
      render(conn, :find_proxy, %{user: user})
    end
  end
end
