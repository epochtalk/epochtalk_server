import Config

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
