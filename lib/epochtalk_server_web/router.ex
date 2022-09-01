defmodule EpochtalkServerWeb.Router do
  use EpochtalkServerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end
  pipeline :maybe_auth do
    plug Guardian.Plug.Pipeline, module: EpochtalkServer.Auth.Guardian,
                               error_handler: EpochtalkServerWeb.GuardianErrorHandler

    plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
    plug Guardian.Plug.LoadResource, allow_blank: true
  end
  pipeline :enforce_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end
  pipeline :enforce_not_auth do
    plug Guardian.Plug.EnsureNotAuthenticated
  end

  scope "/api", EpochWeb do
    pipe_through [:api, :maybe_auth, :enforce_auth]
    get "/authenticate", AuthController, :authenticate
  end
  scope "/api", EpochtalkServerWeb do
    pipe_through [:api, :maybe_auth, :enforce_not_auth]
    post "/login", AuthController, :login
  end
  scope "/api", EpochtalkServerWeb do
    pipe_through [:api, :maybe_auth]
    get "/register/username/:username", AuthController, :username
    get "/register/email/:email", AuthController, :email
    post "/register", AuthController, :register
    delete "/logout", AuthController, :logout
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
