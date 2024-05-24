import Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with esbuild to bundle .js and .css sources.
config :epochtalk_server, EpochtalkServerWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: false,
  secret_key_base: "9ORa6oGSN+xlXNedSn0gIKVc/6//naQqSiZsRJ8vNbcvHpPOTPMLgcn134WIH3Pd",
  watchers: []

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
