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
    # Track IP address of users making POST, PUT or PATCH requests
    plug EpochtalkServerWeb.Plugs.TrackIp
    # Track user last active
    plug EpochtalkServerWeb.Plugs.UserLastActive
  end

  pipeline :enforce_auth do
    plug Guardian.Plug.Pipeline,
      module: EpochtalkServer.Auth.Guardian,
      error_handler: EpochtalkServerWeb.GuardianErrorHandler

    plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
    plug Guardian.Plug.LoadResource, allow_blank: false
    plug Guardian.Plug.EnsureAuthenticated
    # Track IP address of users making POST, PUT or PATCH requests
    plug EpochtalkServerWeb.Plugs.TrackIp
    # Track user last active
    plug EpochtalkServerWeb.Plugs.UserLastActive
  end

  scope "/api", EpochtalkServerWeb.Controllers do
    pipe_through [:api, :enforce_auth]
    get "/users/preferences", Preference, :preferences
    get "/mentions", Mention, :page
    get "/notifications/counts", Notification, :counts
    post "/notifications/dismiss", Notification, :dismiss
    get "/authenticate", User, :authenticate
    get "/admin/roles/all", Role, :all
    put "/admin/roles/update", Role, :update
    post "/threads", Thread, :create
    post "/threads/:thread_id/polls/vote", Thread, :vote
    post "/threads/:thread_id/polls/lock", Thread, :lock_poll
    put "/threads/:thread_id/polls/:id", Thread, :update_poll
    get "/admin/modlog", ModerationLog, :page
    get "/boards/movelist", Board, :movelist
  end

  scope "/api", EpochtalkServerWeb.Controllers do
    pipe_through [:api, :maybe_auth]
    get "/boards", Board, :by_category
    get "/boards/:id", Board, :find
    get "/boards/:slug/id", Board, :slug_to_id
    get "/breadcrumbs", Breadcrumb, :breadcrumbs
    get "/threads", Thread, :by_board
    get "/threads/:slug/id", Thread, :slug_to_id
    post "/threads/:id/viewed", Thread, :viewed
    get "/threads/recent", Thread, :recent
    get "/register/username/:username", User, :username
    get "/register/email/:email", User, :email
    get "/posts", Post, :by_thread
    get "/posts/draft", PostDraft, :by_user_id
    put "/posts/draft", PostDraft, :upsert
    post "/posts", Post, :create
    post "/posts/:id", Post, :update
    post "/register", User, :register
    post "/login", User, :login
    post "/confirm", User, :confirm
    delete "/logout", User, :logout
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
