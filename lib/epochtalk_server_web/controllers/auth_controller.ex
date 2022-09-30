defmodule EpochtalkServerWeb.AuthController do
  use EpochtalkServerWeb, :controller
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Ban
  alias EpochtalkServer.Models.Invitation
  # alias EpochtalkServer.Models.BoardModerator
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServer.Session
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.CustomErrors.{
    InvalidCredentials,
    NotLoggedIn,
    AccountNotConfirmed,
    AccountMigrationNotComplete,
    InvalidPayload
  }

  def username(conn, %{"username" => username}), do: render(conn, "search.json", found: User.with_username_exists?(username))
  def email(conn, %{"email" => email}), do: render(conn, "search.json", found: User.with_email_exists?(email))

  # TODO(akinsey): handle config.inviteOnly
  # TODO(akinsey): handle config.newbieEnabled
  # TODO(akinsey): Send confirmation email
  def register(conn, %{"username" => _, "email" => _, "password" => _} = attrs) do
    with {:auth, false} <- {:auth, Guardian.Plug.authenticated?(conn)},
         {:ok, user} <- User.create_fixed(attrs),
         {_count, nil} <- Invitation.delete(user.email),
         {:ok, user} <- User.handle_malicious_user(user, conn.remote_ip),
         {:ok, user, token, conn} <- Session.create(user, false, conn) do
      render(conn, "user.json", %{ user: user, token: token})
    else
      # user already authenticated
      {:auth, true} -> authenticate(conn)
      # error banning in handle_malicious_user
      {:error, :ban_error} -> ErrorHelpers.render_json_error(conn, 500, "There was an error banning malicious user, upon login")
      # error in user.create
      {:error, data} -> ErrorHelpers.render_json_error(conn, 400, data)
      # Catch all for any other errors
      _ -> ErrorHelpers.render_json_error(conn, 500, "There was an issue registering")
    end
  end
  def register(_conn, _attrs), do: raise(InvalidPayload)

  def authenticate(conn), do: authenticate(conn, nil)
  def authenticate(conn, _attrs) do
    token = Guardian.Plug.current_token(conn)
    user = Guardian.Plug.current_resource(conn)
    render(conn, "user.json", %{ user: user, token: token})
  end

  # TODO: check if user is on page that requires auth
  def logout(conn, _attrs) do
    with {:auth, true} <- {:auth, Guardian.Plug.authenticated?(conn)},
         conn <- Guardian.Plug.sign_out(conn) do
      render(conn, "logout.json")
    else
      {:auth, false} -> raise(NotLoggedIn)
      _ -> ErrorHelpers.render_json_error(conn, 500, "There was an issue signing out")
    end
  end

  def login(conn, attrs) when not is_map_key(attrs, "rememberMe"), do: login(conn, Map.put(attrs, "rememberMe", false))
  # def login(conn, %{"username" => username, "password" => password, "rememberMe" => _} = _attrs) do
  #   with {:auth, false} <- {:auth, Guardian.Plug.authenticated?(conn)},
  #        {:ok, user} <- User.by_username(username),
  #        {:not_confirmed, false} <- {:not_confirmed, !!Map.get(user, :confirmation_token)},
  #        {:missing_passhash, true} <- {:missing_passhash, !!Map.get(user, :passhash)},
  #        {:valid_password, true} <- {:valid_password, User.valid_password?(user, password)},
  #        {:ok, user} <- Ban.unban(user),
  #        {:ok, user} <- BoardModerator.get_boards(user),
  #        {user, conn} <- Session.create(user, conn) do
  #     render(conn, "user.json", user: user)
  #   else
  #     {:auth, true} -> authenticate(conn)
  #     {:error, :user_not_found} -> raise(InvalidCredentials)
  #     {:not_confirmed, true} -> raise(AccountNotConfirmed)
  #     {:missing_passhash, false} -> raise(AccountMigrationNotComplete)
  #     {:valid_password, false} -> raise(InvalidCredentials)
  #     {:error, :unban_error} -> ErrorHelpers.render_json_error(conn, 500, "There was an issue unbanning user, upon login")
  #     _ -> ErrorHelpers.render_json_error(conn, 500, "There was an issue signing out")
  #   end
  # end
  def login(conn, %{"username" => username, "password" => password, "rememberMe" => remember_me} = _attrs) do
    with {:auth, false} <- {:auth, Guardian.Plug.authenticated?(conn)},
         {:ok, user} <- User.by_username_fixed(username),
         {:not_confirmed, false} <- {:not_confirmed, !!Map.get(user, :confirmation_token)},
         {:missing_passhash, true} <- {:missing_passhash, !!Map.get(user, :passhash)},
         {:valid_password, true} <- {:valid_password, User.valid_password?(user, password)},
         {:ok, user} <- Ban.unban_fixed(user),
         {:ok, user, token, conn} <- Session.create(user, remember_me, conn) do
      render(conn, "user.json", %{ user: user, token: token})
    else
      {:auth, true} -> authenticate(conn)
      {:error, :user_not_found} -> raise(InvalidCredentials)
      {:not_confirmed, true} -> raise(AccountNotConfirmed)
      {:missing_passhash, false} -> raise(AccountMigrationNotComplete)
      {:valid_password, false} -> raise(InvalidCredentials)
      {:error, :unban_error} -> ErrorHelpers.render_json_error(conn, 500, "There was an issue unbanning user, upon login")
      _ -> ErrorHelpers.render_json_error(conn, 500, "There was an issue while attempting to login")
    end
  end
  def login(_conn, _attrs), do: raise(InvalidPayload)
end
