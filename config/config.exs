# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :epochtalk_server,
  ecto_repos: [EpochtalkServer.Repo],
  frontend_config: %{
    frontend_url: "http://localhost:8000",
    backend_url: "http://localhost:4000",
    newbie_enabled: false,
    login_required: false,
    invite_only: false,
    verify_registration: true,
    post_max_length: 10_000,
    max_image_size: 10_485_760,
    max_avatar_size: 102_400,
    mobile_break_width: 767,
    ga_key: "UA-XXXXX-Y",
    revision: nil,
    website: %{
      title: "Epochtalk Forums",
      description: "Open source forum software",
      keywords: "open source, free forum, forum software, forum",
      logo: nil,
      favicon: nil,
      default_avatar: "/images/avatar.png",
      default_avatar_shape: "circle"
    },
    portal: %{enabled: false, board_id: nil},
    emailer: %{ses_mode: false, options: %{from_address: "info@epochtalk.com"}},
    images: %{s3_mode: false, options: %{local_host: "http://localhost:4000"}},
    rate_limiting: %{}
  }

# Configure Guardian
config :epochtalk_server, EpochtalkServer.Auth.Guardian,
  issuer: "EpochtalkServer",
  secret_key: "Secret key. You can use `mix guardian.gen.secret` to get one"

# Configure Guardian.DB
config :guardian, Guardian.DB, repo: GuardianRedis.Repo
# schema_name: "guardian_tokens" # default
# token_types: ["refresh_token"] # store all token types if not set

# Configures the endpoint
config :epochtalk_server, EpochtalkServerWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: EpochtalkServerWeb.Controllers.ErrorJSON],
    layout: false
  ],
  pubsub_server: EpochtalkServer.PubSub,
  live_view: [signing_salt: "2Ay27BWv"]

# Configures the mailer
#
# By default "SMTP" adapter is being used.
#
# For Development `config/dev.exs` loads the "Local" adapter which allows preview
# of sent emails at the url `/dev/mailbox`. To test SMTP in Development mode,
# mailer configurations for adapter, credentials and other options can be
# overriden in `config/dev.secret.exs`
#
# For production configurations are fetched from system environment variables.
# Overrides for production are in `config/runtime.exs`.
config :epochtalk_server, EpochtalkServer.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: "smtp.example.com",
  username: "username",
  password: "password",
  ssl: true,
  tls: :if_available,
  auth: :always,
  port: 465,
  retries: 2,
  no_mx_lookups: false

# dkim: [
#   s: "default", d: "domain.com",
#   private_key: {:pem_plain, File.read!("priv/keys/domain.private")}
# ]

# configure aws
config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, {:awscli, "default", 30}, :instance_role],
  secret_access_key: [
    {:system, "AWS_SECRET_ACCESS_KEY"},
    {:awscli, "default", 30},
    :instance_role
  ],
  region: {:system, "AWS_REGION"}

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :remote_ip]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
