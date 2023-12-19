import Config

# Configure your database
config :epochtalk_server, EpochtalkServer.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("DATABASE_USER"),
  password: System.get_env("DATABASE_PASSWORD"),
  database: System.get_env("DATABASE_NAME"),
  hostname: System.get_env("DATABASE_HOST"),
  pool_size: 10

config :epochtalk_server,
  ecto_repos: [EpochtalkServer.Repo],
  frontend_config: %{
    frontend_url: System.get_env("FRONTEND_URL") || "http://localhost:8000",
    backend_url: System.get_env("BACKEND_URL") || "http://localhost:4000",
    ga_key: System.get_env("GA_KEY") || "UA-XXXXX-Y",
    emailer: %{ses_mode: System.get_env("EMAILER_SES_MODE") || false, options: %{from_address: System.get_env("EMAILER_FROM_ADDRESS") || "info@epochtalk.com"}},
    images: %{s3_mode: System.get_env("IMAGES_S3_MODE") || false, options: %{local_host: System.get_env("IMAGES_LOCAL_HOST") || "http://localhost:4000"}}
  }
