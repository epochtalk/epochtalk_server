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
config :epochtalk_server, EpochtalkServer.Guardian,
       issuer: "EpochtalkServer",
       # TODO: configure this at runtime through env
       secret_key: "Secret key. You can use `mix guardian.gen.secret` to get one"

# Configure Guardian.DB
config :guardian, Guardian.DB,
  repo: GuardianRedis.Repo
  # schema_name: "guardian_tokens" # default
  # token_types: ["refresh_token"] # store all token types if not set

# Configure GuardianRedis
# (implementation of Guardian.DB storage in redis)
config :guardian_redis, :redis,
  host: "127.0.0.1",
  port: 6379,
  pool_size: 10

# Configures the endpoint
config :epochtalk_server, EpochtalkServerWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: EpochtalkServerWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: EpochtalkServer.PubSub,
  live_view: [signing_salt: "2Ay27BWv"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :epochtalk_server, EpochtalkServer.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
