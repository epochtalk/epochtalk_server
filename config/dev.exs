import Config

config :epochtalk_server, EpochtalkServer.SmfRepo,
  username: System.get_env("SMF_REPO_USERNAME"),
  password: System.get_env("SMF_REPO_PASSWORD"),
  hostname: System.get_env("SMF_REPO_HOSTNAME"),
  database: System.get_env("SMF_REPO_DATABASE"),
  port: String.to_integer(System.get_env("SMF_REPO_PORT") || "3306"),
  stacktrace: System.get_env("SMF_REPO_STACKTRACE") || true,
  show_sensitive_data_on_connection_error:
    System.get_env("SMF_REPO_SENSITIVE_DATA_ON_ERROR") || true,
  pool_size: String.to_integer(System.get_env("SMF_REPO_POOL_SIZE") || "10")

# For Development `config/dev.exs` loads the "Local" adapter which allows preview
# of sent emails at the url `/dev/mailbox`. To test SMTP in Development mode,
# mailer configurations for adapter, credentials and other options can be
# overriden in `config/dev.secret.exs`
config :epochtalk_server, EpochtalkServer.Mailer, adapter: Swoosh.Adapters.Local

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

if File.exists?("config/dev.secret.exs") do
  import_config "dev.secret.exs"
end
