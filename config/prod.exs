import Config

# Do not print debug messages in production
config :logger, level: :info

config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: EpochtalkServer.Finch

if File.exists?("config/prod.secret.exs") do
  import_config "prod.secret.exs"
end
