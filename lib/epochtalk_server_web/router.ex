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

    plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
    plug Guardian.Plug.LoadResource, allow_blank: true
  end

  pipeline :enforce_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  scope "/api", EpochtalkServerWeb do
    pipe_through [:api, :maybe_auth, :enforce_auth]
    get "/authenticate", UserController, :authenticate
    get "/users/preferences", PreferenceController, :preferences
    get "/mentions", MentionController, :page
    get "/notifications/counts", NotificationController, :counts
    post "/notifications/dismiss", NotificationController, :dismiss
    get "/admin/modlog", ModerationLogController, :page
  end

  scope "/api", EpochtalkServerWeb do
    pipe_through [:api, :maybe_auth]
    get "/register/username/:username", UserController, :username
    get "/register/email/:email", UserController, :email
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
