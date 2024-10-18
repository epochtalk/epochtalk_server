import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/epochtalk_server start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :epochtalk_server, EpochtalkServerWeb.Endpoint, server: true
end

## Env access helper functions
get_env_or_raise_with_message = fn env_var, message ->
  System.get_env(env_var) ||
    raise """
    environment variable #{env_var} missing.
    #{message}
    """
end

get_env_or_raise = fn env_var ->
  get_env_or_raise_with_message.(env_var, "")
end

get_env_cast_integer_with_default = fn env_var, default ->
  System.get_env(env_var, default) |> String.to_integer()
end

get_env_cast_bool_with_default = fn env_var, default ->
  System.get_env(env_var, default) == "TRUE"
end

get_env_cast_bool = fn env_var ->
  get_env_cast_bool_with_default.(env_var, "FALSE")
end

## Conditionally load env configurations from dotenv
case config_env() do
  :prod ->
    nil

  :test ->
    # if testing anywhere other than in CI, load example.env
    # this helps ensure tests always work when running locally in dev
    #
    # set CI to "TRUE" when testing in CI
    # variables in CI should be set directly through the environment
    unless get_env_cast_bool.("CI") do
      DotenvParser.load_file("example.env")
    end

  _ ->
    DotenvParser.load_file(".env")
end

## Configure Rate limiter
# Rate limiter is re-configurable during app runtime;
# here we call its init function
EpochtalkServer.RateLimiter.init()

## Frontend configurations
config :epochtalk_server, :frontend_config, %{
  frontend_url: System.get_env("FRONTEND_URL", "http://localhost:8000"),
  backend_url: System.get_env("BACKEND_URL", "http://localhost:4000"),
  newbie_enabled: get_env_cast_bool_with_default.("NEWBIE_ENABLED", "FALSE"),
  login_required: get_env_cast_bool_with_default.("LOGIN_REQUIRED", "FALSE"),
  invite_only: get_env_cast_bool_with_default.("INVITE_ONLY", "FALSE"),
  verify_registration: get_env_cast_bool_with_default.("VERIFY_REGISTRATION", "FALSE"),
  post_max_length: get_env_cast_integer_with_default.("POST_MAX_LENGTH", "10000"),
  max_image_size: get_env_cast_integer_with_default.("MAX_IMAGE_SIZE", "10485760"),
  max_avatar_size: get_env_cast_integer_with_default.("MAX_AVATAR_SIZE", "102400"),
  mobile_break_width: get_env_cast_integer_with_default.("MOBILE_BREAK_WIDTH", "767"),
  ga_key: System.get_env("GA_KEY", "UA-XXXXX-Y"),
  revision: nil,
  website: %{
    title: System.get_env("WEBSITE_TITLE", "Epochtalk Forums"),
    description: System.get_env("WEBSITE_DESCRIPTION", "Open source forum software"),
    keywords:
      System.get_env("WEBSITE_KEYWORDS", "open source, free forum, forum software, forum"),
    logo: System.get_env("WEBSITE_LOGO"),
    favicon: System.get_env("WEBSITE_FAVICON"),
    default_avatar: System.get_env("WEBSITE_DEFAULT_AVATAR", "/images/avatar.png"),
    default_avatar_shape: System.get_env("WEBSITE_DEFAULT_AVATAR_SHAPE", "circle")
  },
  portal: %{
    enabled: get_env_cast_bool_with_default.("PORTAL_ENABLED", "FALSE"),
    board_id: System.get_env("PORTAL_BOARD_ID")
  },
  emailer: %{
    ses_mode: get_env_cast_bool_with_default.("EMAILER_SES_MODE", "FALSE"),
    options: %{
      from_address: System.get_env("EMAILER_OPTIONS_FROM_ADDRESS", "info@epochtalk.com")
    }
  },
  images: %{
    s3_mode: System.get_env("IMAGES_S3_MODE", "FALSE"),
    options: %{
      local_host: System.get_env("IMAGES_OPTIONS_LOCAL_HOST", "http://localhost:4000")
    }
  },
  rate_limiting: %{}
}

## Guardian configurations
guardian_config =
  case config_env() do
    :prod ->
      [
        issuer: "EpochtalkServer",
        secret_key:
          get_env_or_raise_with_message.(
            "GUARDIAN_SECRET_KEY",
            "You can generate one by calling: mix guardian.gen.secret"
          )
      ]

    _ ->
      [
        issuer: "EpochtalkServer",
        secret_key: "Secret key. You can use `mix guardian.gen.secret` to get one"
      ]
  end

config :epochtalk_server, EpochtalkServer.Auth.Guardian, guardian_config

## Redis configurations
redis_config =
  case config_env() do
    :prod ->
      %{
        redis_host: System.get_env("REDIS_HOST", "127.0.0.1"),
        redis_port: get_env_cast_integer_with_default.("REDIS_PORT", "6379"),
        redis_pool_size: get_env_cast_integer_with_default.("REDIS_POOL_SIZE", "10"),
        redis_database: get_env_cast_integer_with_default.("REDIS_DATABASE", "0")
      }

    :dev ->
      %{
        redis_host: "127.0.0.1",
        redis_port: 6379,
        redis_pool_size: 10,
        redis_database: 0
      }

    :test ->
      %{
        redis_host: "127.0.0.1",
        redis_port: 6379,
        redis_pool_size: 10,
        # tests use separate redis database (doesn't interfere with dev)
        redis_database: 1
      }
  end

# Configure Guardian Redis
config :guardian_redis, :redis,
  host: redis_config[:redis_host],
  port: redis_config[:redis_port],
  pool_size: redis_config[:redis_pool_size],
  database: redis_config[:redis_database]

# Configure Redis for Session Storage
config :epochtalk_server, :redix,
  host: redis_config[:redis_host],
  port: redis_config[:redis_port],
  database: redis_config[:redis_database],
  name: :redix

# Configure hammer for rate limiting
config :hammer,
  backend: {
    Hammer.Backend.Redis,
    [
      # two hours
      expiry_ms: 1_000 * 60 * 60 * 2,
      redix_config: [
        host: redis_config[:redis_host],
        port: redis_config[:redis_port],
        database: redis_config[:redis_database]
      ],
      pool_size: 4,
      pool_max_overflow: 2
    ]
  }

## Database configurations
database_config =
  case config_env() do
    :dev ->
      [
        username: "postgres",
        password: "postgres",
        hostname: "localhost",
        database: "epochtalk_server_dev",
        stacktrace: true,
        show_sensitive_data_on_connection_error: true,
        pool_size: 10
      ]

    :test ->
      # The MIX_TEST_PARTITION environment variable can be used
      # to provide built-in test partitioning in CI environment.
      # Run `mix help test` for more information.
      [
        username: "postgres",
        password: "postgres",
        hostname: "localhost",
        database: "epochtalk_server_test#{System.get_env("MIX_TEST_PARTITION")}",
        pool: Ecto.Adapters.SQL.Sandbox,
        pool_size: 10
      ]

    :prod ->
      database_url =
        get_env_or_raise_with_message.(
          "DATABASE_URL",
          "For example: ecto://USER:PASS@HOST/DATABASE"
        )

      maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

      [
        url: database_url,
        pool_size: get_env_cast_integer_with_default.("POOL_SIZE", "10"),
        socket_options: maybe_ipv6
      ]
  end

config :epochtalk_server, EpochtalkServer.Repo, database_config

## AWS Configurations
aws_config =
  case config_env() do
    :dev ->
      [
        access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, {:awscli, "default", 30}, :instance_role],
        secret_access_key: [
          {:system, "AWS_SECRET_ACCESS_KEY"},
          {:awscli, "default", 30},
          :instance_role
        ],
        region: {:system, "AWS_REGION"}
      ]

    _ ->
      [
        access_key_id: get_env_or_raise.("AWS_ACCESS_KEY_ID"),
        secret_access_key: get_env_or_raise.("AWS_SECRET_ACCESS_KEY"),
        region: get_env_or_raise.("AWS_REGION")
      ]
  end

config :ex_aws, aws_config

## S3 configurations
# configure s3 if images mode is "S3"
if System.get_env("IMAGES_MODE") == "S3" do
  bucket =
    case config_env() do
      :test ->
        System.get_env("S3_BUCKET", "epochtalk_server_test")

      _ ->
        get_env_or_raise.("S3_BUCKET")
    end

  # configure s3
  config :epochtalk_server, EpochtalkServer.S3,
    expire_after_hours: get_env_cast_integer_with_default.("S3_EXPIRE_AFTER_HOURS", "1"),
    # 1 KB
    min_size_bytes: get_env_cast_integer_with_default.("S3_MIN_SIZE_BYTES", "1024"),
    # 10 MB
    max_size_bytes: get_env_cast_integer_with_default.("S3_MAX_SIZE_BYTES", "10485760"),
    content_type_starts_with: System.get_env("S3_CONTENT_TYPE_STARTS_WITH", "image/"),
    # virtual_host:
    #   true -> https://<bucket>.s3.<region>.amazonaws.com
    #   false -> https://s3.<region>.amazonaws.com/<bucket>
    virtual_host: get_env_cast_bool_with_default.("S3_VIRTUAL_HOST", "TRUE"),
    bucket: bucket,
    path: System.get_env("S3_PATH", "images/")
end

## Configure endpoint
base_endpoint_config = [
  url: [host: "localhost"],
  render_errors: [
    formats: [json: EpochtalkServerWeb.Controllers.ErrorJSON],
    layout: false
  ],
  pubsub_server: EpochtalkServer.PubSub,
  live_view: [signing_salt: "2Ay27BWv"],
  secret_key_base:
    get_env_or_raise_with_message.(
      "SECRET_KEY_BASE",
      """
      You can generate one by calling: mix phx.gen.secret
      If running in dev mode, add it to .env
      """
    )
]

# Secret key base is used to sign/encrypt cookies and other secrets.
endpoint_secret_key_base =
  endpoint_config =
  case config_env() do
    :dev ->
      # For development, we disable any cache and enable
      # debugging and code reloading.
      #
      # The watchers configuration can be used to run external
      # watchers to your application. For example, we use it
      # with esbuild to bundle .js and .css sources.
      [
        # Binding to loopback ipv4 address prevents access from other machines.
        # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
        http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: 4000],
        check_origin: false,
        code_reloader: true,
        debug_errors: false,
        watchers: []
      ]

    :test ->
      # We don't run a server during test. If one is required,
      # you can enable the server option below.
      [
        http: [ip: {127, 0, 0, 1}, port: 4002],
        server: false
      ]

    :prod ->
      host = get_env_or_raise.("PHX_HOST")
      port = get_env_cast_integer_with_default.("PORT", "4000")

      [
        # Include the path to a cache manifest
        # containing the digested version of static files. This
        # manifest is generated by the `mix phx.digest` task,
        # which you should run after static files are built and
        # before starting your production server.
        cache_static_manifest: "priv/static/cache_manifest.json",
        url: [host: host, port: 443, scheme: "https"],
        http: [
          # Enable IPv6 and bind on all interfaces.
          # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
          # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
          # for details about using IPv6 vs IPv4 and loopback vs public addresses.
          ip: {0, 0, 0, 0, 0, 0, 0, 0},
          port: port
        ]
      ]
  end

config :epochtalk_server,
       EpochtalkServerWeb.Endpoint,
       Keyword.merge(base_endpoint_config, endpoint_config)

## Configure mailer in prod
#  (Other envs are hardcoded into their respective config/ files)
if config_env() == :prod do
  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :epochtalk_server, EpochtalkServer.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
  if System.get_env("EMAILER_SES_MODE") do
    emailer_ses_region = get_env_or_raise.("EMAILER_SES_REGION")
    emailer_ses_aws_access_key = get_env_or_raise.("EMAILER_SES_AWS_ACCESS_KEY")
    emailer_ses_aws_secret_key = get_env_or_raise.("EMAILER_SES_AWS_SECRET_KEY")

    config :epochtalk_server, EpochtalkServer.Mailer,
      adapter: Swoosh.Adapters.AmazonSES,
      region: emailer_ses_region,
      access_key: emailer_ses_aws_access_key,
      secret: emailer_ses_aws_secret_key
  else
    config :epochtalk_server, EpochtalkServer.Mailer,
      relay: System.get_env("EMAILER_SMTP_RELAY", "smtp.example.com"),
      username: System.get_env("EMAILER_SMTP_USERNAME", "username"),
      password: System.get_env("EMAILER_SMTP_PASSWORD", "password"),
      port: get_env_cast_integer_with_default.("EMAILER_SMTP_PORT", "465")
  end
end

##### PROXY REPO CONFIGURATIONS #####

# conditionally show debug logs in prod
if config_env() == :prod do
  logger_level =
    System.get_env("LOGGER_LEVEL")
    |> case do
      "DEBUG" -> :debug
      _ -> :info
    end

  config :logger, level: logger_level
end

# Configure proxy sequences and boards blacklist
proxy_config =
  case config_env() do
    :prod ->
      id_board_blacklist =
        get_env_or_raise_with_message.(
          "ID_BOARD_BLACKLIST",
          "environment variable ID_BOARD_BLACKLIST is missing."
        )

      id_board_blacklist =
        id_board_blacklist
        |> String.split()
        |> Enum.map(&String.to_integer(&1))

      %{
        threads_seq: System.get_env("THREADS_SEQ") || "6000000",
        boards_seq: System.get_env("BOARDS_SEQ") || "500",
        id_board_blacklist: id_board_blacklist
      }

    :dev ->
      %{
        threads_seq: "6000000",
        boards_seq: "500",
        id_board_blacklist: []
      }

    # default thread/board seq and empty blacklist
    _ ->
      %{
        threads_seq: "0",
        boards_seq: "0",
        id_board_blacklist: []
      }
  end

config :epochtalk_server, proxy_config: proxy_config

# Configure SmfRepo for proxy
# - do not configure for testing
if config_env() != :test do
  smf_repo_username =
    get_env_or_raise_with_message.(
      "SMF_REPO_USERNAME",
      "environment variable SMF_REPO_USERNAME is missing."
    )

  smf_repo_password =
    get_env_or_raise_with_message.(
      "SMF_REPO_PASSWORD",
      "environment variable SMF_REPO_PASSWORD is missing."
    )

  smf_repo_hostname =
    get_env_or_raise_with_message.(
      "SMF_REPO_HOSTNAME",
      "environment variable SMF_REPO_HOSTNAME is missing."
    )

  smf_repo_database =
    get_env_or_raise_with_message.(
      "SMF_REPO_DATABASE",
      "environment variable SMF_REPO_DATABASE is missing."
    )

  proxy_repo_config =
    case config_env() do
      :prod ->
        [
          username: smf_repo_username,
          password: smf_repo_password,
          hostname: smf_repo_hostname,
          database: smf_repo_database,
          port: get_env_cast_integer_with_default.("SMF_REPO_PORT", "3306"),
          stacktrace: get_env_cast_bool_with_default.("SMF_REPO_STACKTRACE", "TRUE"),
          show_sensitive_data_on_connection_error:
            get_env_cast_bool_with_default.("SMF_REPO_SENSITIVE_DATA_ON_ERROR", "FALSE"),
          pool_size: get_env_cast_integer_with_default.("SMF_REPO_POOL_SIZE", "10")
        ]

      _ ->
        [
          username: smf_repo_username,
          password: smf_repo_password,
          hostname: smf_repo_hostname,
          database: smf_repo_database,
          port: get_env_cast_integer_with_default.("SMF_REPO_PORT", "3306"),
          stacktrace: true,
          show_sensitive_data_on_connection_error: true,
          pool_size: get_env_cast_integer_with_default.("SMF_REPO_POOL_SIZE", "10")
        ]
    end

  config :epochtalk_server, EpochtalkServer.SmfRepo, proxy_repo_config
end
