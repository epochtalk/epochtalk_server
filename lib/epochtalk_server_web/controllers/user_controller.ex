defmodule EpochtalkServerWeb.UserController do
  use EpochtalkServerWeb, :controller
  @moduledoc """
  Controller For `User` related API requests
  """
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Ban
  alias EpochtalkServer.Models.Invitation
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServer.Session
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.CustomErrors.InvalidPayload

  @doc """
  Used to check if a username has already been taken
  """
  def username(conn, %{"username" => username}), do: render(conn, "username.json", data: %{found: User.with_username_exists?(username)})

  @doc """
  Used to check if an email has already been taken
  """
  def email(conn, %{"email" => email}), do: render(conn, "email.json", data: %{found: User.with_email_exists?(email)})

  @doc """
  Registers a new `User`

  - TODO(akinsey): handle config.inviteOnly
  - TODO(akinsey): handle config.newbieEnabled
  - TODO(akinsey): Send confirmation email
  """
  def register(conn, %{"username" => _, "email" => _, "password" => _} = attrs) do
    with {:auth, false} <- {:auth, Guardian.Plug.authenticated?(conn)}, # check auth
         {:ok, user} <- User.create(attrs), # create user
         {_count, nil} <- Invitation.delete(user.email), # delete invitation
         {:ok, user} <- User.handle_malicious_user(user, conn.remote_ip), # ban if malicious
         {:ok, user, token, conn} <- Session.create(user, false, conn) do # create session
      render(conn, "user.json", %{ user: user, token: token})
    else
      # user already authenticated
      {:auth, true} -> ErrorHelpers.render_json_error(conn, 400, "Cannot register a new account while logged in")
      # error banning in handle_malicious_user
      {:error, :ban_error} -> ErrorHelpers.render_json_error(conn, 500, "There was an error banning malicious user, upon login")
      # error in user.create
      {:error, data} -> ErrorHelpers.render_json_error(conn, 400, data)
      # Catch all for any other errors
      _ -> ErrorHelpers.render_json_error(conn, 500, "There was an issue registering")
    end
  end
  def register(_conn, _attrs), do: raise(InvalidPayload)

  @doc """
  Authenticates currently logged in `User`
  """
  def authenticate(conn, _attrs) do
    token = Guardian.Plug.current_token(conn)
    user = Guardian.Plug.current_resource(conn)
    render(conn, "user.json", %{ user: user, token: token})
  end

  @doc """
  Logs out the logged in `User`

  - TODO(boka): check if user is on page that requires auth
  - TODO(boka): Delete users session
  """
  def logout(conn, _attrs) do
    with {:auth, true} <- {:auth, Guardian.Plug.authenticated?(conn)},
         conn <- Guardian.Plug.sign_out(conn) do
      render(conn, "logout.json", data: %{success: true})
    else
      {:auth, false} -> ErrorHelpers.render_json_error(conn, 400, "Not logged in")
      _ -> ErrorHelpers.render_json_error(conn, 500, "There was an issue signing out")
    end
  end

  @doc """
  Logs in an existing `User`
  """
  def login(conn, attrs) when not is_map_key(attrs, "rememberMe"), do: login(conn, Map.put(attrs, "rememberMe", false))
  def login(conn, %{"username" => username, "password" => password, "rememberMe" => remember_me} = _attrs) do
    with {:auth, false} <- {:auth, Guardian.Plug.authenticated?(conn)},
         {:ok, user} <- User.by_username(username),
         {:not_confirmed, false} <- {:not_confirmed, !!Map.get(user, :confirmation_token)},
         {:missing_passhash, true} <- {:missing_passhash, !!Map.get(user, :passhash)},
         {:valid_password, true} <- {:valid_password, User.valid_password?(user, password)},
         {:ok, user} <- Ban.unban(user),
         {:ok, user, token, conn} <- Session.create(user, remember_me, conn) do
      render(conn, "user.json", %{ user: user, token: token})
    else
      {:auth, true} -> ErrorHelpers.render_json_error(conn, 400, "Already logged in")
      {:error, :user_not_found} -> ErrorHelpers.render_json_error(conn, 400, "Invalid credentials")
      {:not_confirmed, true} -> ErrorHelpers.render_json_error(conn, 400, "User account not confirmed")
      {:missing_passhash, false} -> ErrorHelpers.render_json_error(conn, 403, "User account migration not complete, please reset password")
      {:valid_password, false} -> ErrorHelpers.render_json_error(conn, 400, "Invalid credentials")
      {:error, :unban_error} -> ErrorHelpers.render_json_error(conn, 500, "There was an issue unbanning user, upon login")
      _ -> ErrorHelpers.render_json_error(conn, 500, "There was an issue while attempting to login")
    end
  end
  def login(_conn, _attrs), do: raise(InvalidPayload)

end
