defmodule EpochtalkServerWeb.AuthController do
  use EpochtalkServerWeb, :controller
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServer.Session

  alias EpochtalkServerWeb.CustomErrors.{
    InvalidCredentials,
    NotLoggedIn,
    AccountNotConfirmed,
    AccountMigrationNotComplete
  }
  alias EpochtalkServerWeb.ErrorView

  def username(conn, %{"username" => username}) do
    username_found = username
    |> User.with_username_exists?

    render(conn, "search.json", found: username_found)
  end
  def email(conn, %{"email" => email}) do
    email_found = email
    |> User.with_email_exists?

    render(conn, "search.json", found: email_found)
  end
  def register(conn, attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        conn
        |> render("show.json", user: user)
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_view(ErrorView)
        |> render("400.json", %{message: inspect(changeset.errors)})
    end
  end
  def authenticate(conn, _attrs) do
    user = conn
    |> Guardian.Plug.current_resource

    token = conn
    |> Guardian.Plug.current_token

    user = Map.put(user, :token, token)

    conn
    |> render("credentials.json", user: user)
  end
  def logout(conn, _attrs) do
    if Guardian.Plug.authenticated?(conn) do
      # TODO: check if user is on page that requires auth
      conn
      |> Guardian.Plug.sign_out
      |> render("logout.json")
    else
      raise(NotLoggedIn)
    end
  end
  def login(conn, user_params) when not is_map_key(user_params, "rememberMe") do
    login(conn, Map.put(user_params, "rememberMe", false))
  end
  def login(conn, %{"username" => username, "password" => password} = user_params) do
    user = username
    |> User.by_username

    # check that user exists
    if !user, do: raise(InvalidCredentials)

    # check confirmation token
    if Map.get(user, :confirmation_token), do: raise(AccountNotConfirmed)

    # check user migration
    # if passhash doesn't exist, account hasn't been fully migrated
    if !Map.get(user, :passhash), do: raise(AccountMigrationNotComplete)

    if !User.valid_password?(user, password), do: raise(InvalidCredentials)
    if user = User.by_username(username) do
      # TODO: check ban expiration
      # TODO: get moderated boards
      log_in_user(conn, user, user_params)
    else
      raise(InvalidCredentials)
    end
  end
  defp log_in_user(conn, user, %{"rememberMe" => remember_me}) do
    datetime = NaiveDateTime.utc_now
    session_id = UUID.uuid1()
    decoded_token = %{ user_id: user.id, session_id: session_id, timestamp: datetime }

    # token expiration based on remember_me
    ttl = case remember_me do
      # set longer expiration
      "true" -> {4, :weeks}
      # set default expiration
      _ -> {1, :day}
    end

    token = conn
    |> Guardian.Plug.sign_in(decoded_token, %{}, ttl: ttl)
    |> Guardian.Plug.current_token

    user = Map.put(user, :token, token)
    Session.save(user)

    conn
    |> render("credentials.json", user: user)
  end
end
