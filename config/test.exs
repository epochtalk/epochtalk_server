import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :epochtalk_server, EpochtalkServerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "sFacLki12NmjBfy3rJHugf+w+o36b07r99JfjcDAliabs3JdmQ4GAJKlgPVvaaah",
  server: false

# In test we don't send emails.
config :epochtalk_server, EpochtalkServer.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
# Accept module and parameters
config :logger, :console,
  level: :warning,
  format: "[$level] $message $metadata\n",
  metadata: [:module, :parameters]

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
