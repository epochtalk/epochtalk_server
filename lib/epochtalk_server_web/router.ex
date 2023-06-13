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
    get "/admin/modlog", ModerationLogController, :page
    post "/threads", ThreadController, :create
    get "/admin/roles/all", RoleController, :all
    put "/admin/roles/update", RoleController, :update
    get "/authenticate", UserController, :authenticate
  end

  scope "/api", EpochtalkServerWeb.Controllers do
    pipe_through [:api, :maybe_auth]
    get "/boards", Board, :by_category
    get "/boards/:id", Board, :find
    get "/boards/:slug/id", Board, :slug_to_id
  end

  scope "/api", EpochtalkServerWeb do
    pipe_through [:api, :maybe_auth]
    get "/register/username/:username", UserController, :username
    get "/register/email/:email", UserController, :email
    get "/threads", ThreadController, :by_board
    get "/threads/recent", ThreadController, :recent
    post "/register", UserController, :register
    post "/login", UserController, :login
    post "/confirm", UserController, :confirm
    delete "/logout", UserController, :logout
  end

  scope "/", EpochtalkServerWeb.Controllers do
    get "/config.js", Configuration, :config
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
