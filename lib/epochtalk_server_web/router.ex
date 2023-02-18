defmodule EpochtalkServerWeb.Router do
  use EpochtalkServerWeb, :router
  @env Mix.env()
  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :maybe_auth do
    plug Guardian.Plug.Pipeline,
      module: EpochtalkServer.Auth.Guardian,
      error_handler: EpochtalkServerWeb.GuardianErrorHandler

    # If there is a session token, validate it
    plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
    # If there is an authorization header, validate it
    plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
    # Load the user if either of the verifications worked
    plug Guardian.Plug.LoadResource, allow_blank: true
  end

  pipeline :enforce_auth do
    plug Guardian.Plug.Pipeline,
      module: EpochtalkServer.Auth.Guardian,
      error_handler: EpochtalkServerWeb.GuardianErrorHandler

    plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
    plug Guardian.Plug.LoadResource, allow_blank: false
    plug Guardian.Plug.EnsureAuthenticated
  end

  scope "/api", EpochtalkServerWeb do
    pipe_through [:api, :enforce_auth]
    get "/users/preferences", PreferenceController, :preferences
    get "/mentions", MentionController, :page
    get "/notifications/counts", NotificationController, :counts
    post "/notifications/dismiss", NotificationController, :dismiss
    get "/authenticate", UserController, :authenticate
  end

  scope "/api", EpochtalkServerWeb do
    pipe_through [:api, :maybe_auth]
    get "/register/username/:username", UserController, :username
    get "/register/email/:email", UserController, :email
    get "/boards", BoardController, :by_category
    get "/boards/:id", BoardController, :find
    get "/threads", ThreadController, :by_board
    get "/threads/recent", ThreadController, :recent
    post "/register", UserController, :register
    post "/login", UserController, :login
    post "/confirm", UserController, :confirm
    delete "/logout", UserController, :logout
  end

  scope "/", EpochtalkServerWeb do
    get "/config.js", ConfigurationController, :config
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if @env in [:dev] do
    scope "/dev" do
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
