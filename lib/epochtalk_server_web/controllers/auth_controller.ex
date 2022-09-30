defmodule EpochtalkServerWeb.AuthController do
  use EpochtalkServerWeb, :controller
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Ban
  alias EpochtalkServer.Models.BoardModerator
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServer.Session

  alias EpochtalkServerWeb.CustomErrors.{
    InvalidCredentials,
    NotLoggedIn,
    AccountNotConfirmed,
    AccountMigrationNotComplete,
    InvalidPayload
  }
  alias EpochtalkServerWeb.ErrorView
  alias EpochtalkServerWeb.ErrorHelpers

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
  def register(_conn, _attrs), do: raise(InvalidPayload)

  def authenticate(conn), do: authenticate(conn, nil)
  def authenticate(conn, _attrs) do
    token = Guardian.Plug.current_token(conn)
    user = Guardian.Plug.current_resource(conn) |> Map.put(:token, token)
    render(conn, "user.json", user: user)
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

  def login(conn, attrs) when not is_map_key(attrs, "rememberMe") do
    login(conn, Map.put(attrs, "rememberMe", false))
  end
  def login(conn, %{"username" => username, "password" => password} = _attrs) do
    if Guardian.Plug.authenticated?(conn) do
      authenticate(conn)
    else
      user = User.by_username(username)

      # check that user exists
      if !user, do: raise(InvalidCredentials)

      # check confirmation token
      if Map.get(user, :confirmation_token), do: raise(AccountNotConfirmed)

      # check user migration
      # if passhash doesn't exist, account hasn't been fully migrated
      if !Map.get(user, :passhash), do: raise(AccountMigrationNotComplete)

      # check password
      if !User.valid_password?(user, password), do: raise(InvalidCredentials)

      # unban if ban is expired and update roles
      user = Map.put(user, :roles, Ban.unban_if_expired(user))

      # get user's moderated boards
      user = Map.put(user, :moderating, BoardModerator.get_boards(user.id))

      # create session
      {user, conn} = Session.create(user, conn)

      # reply with user data
      conn
      |> render("user.json", user: user)
    end
  end
  def login(_conn, _attrs), do: raise(InvalidPayload)
end
