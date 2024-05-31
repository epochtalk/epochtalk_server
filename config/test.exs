import Config

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
