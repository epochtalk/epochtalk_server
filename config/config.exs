# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :epochtalk_server,
  ecto_repos: [EpochtalkServer.Repo]

# Configure Guardian
config :epochtalk_server, EpochtalkServer.Auth.Guardian,
       issuer: "EpochtalkServer",
       secret_key: "Secret key. You can use `mix guardian.gen.secret` to get one"

# Configure Guardian.DB
config :guardian, Guardian.DB,
  repo: GuardianRedis.Repo
  # schema_name: "guardian_tokens" # default
  # token_types: ["refresh_token"] # store all token types if not set

# Configure GuardianRedis (for auth)
# (implementation of Guardian.DB storage in redis)
config :guardian_redis, :redis,
  host: "127.0.0.1",
  port: 6379,
  pool_size: 10

# Configures redix (for sessions storage)
config :epochtalk_server, :redix,
  host: "127.0.0.1",
  name: :redix

# Configures the endpoint
config :epochtalk_server, EpochtalkServerWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    view: EpochtalkServerWeb.ErrorView,
    format: "json",
    accepts: ~w(json),
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
