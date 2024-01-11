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

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :epochtalk_server, EpochtalkServer.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :epochtalk_server, EpochtalkServerWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

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
    emailer_ses_region =
      System.get_env("EMAILER_SES_REGION") ||
        raise """
        environment variable EMAILER_SES_REGION is missing.
        """

    emailer_ses_aws_access_key =
      System.get_env("EMAILER_SES_AWS_ACCESS_KEY") ||
        raise """
        environment variable EMAILER_SES_AWS_ACCESS_KEY missing.
        """

    emailer_ses_aws_secret_key =
      System.get_env("EMAILER_SES_AWS_SECRET_KEY") ||
        raise """
        environment variable EMAILER_SES_AWS_SECRET_KEY missing.
        """

    config :epochtalk_server, EpochtalkServer.Mailer,
      adapter: Swoosh.Adapters.AmazonSES,
      region: emailer_ses_region,
      access_key: emailer_ses_aws_access_key,
      secret: emailer_ses_aws_secret_key
  else
    config :epochtalk_server, EpochtalkServer.Mailer,
      relay: System.get_env("EMAILER_SMTP_RELAY") || "smtp.example.com",
      username: System.get_env("EMAILER_SMTP_USERNAME") || "username",
      password: System.get_env("EMAILER_SMTP_PASSWORD") || "password",
      port: System.get_env("EMAILER_SMTP_PORT") || 465
  end

  # Configure SmfRepo for proxy
  smf_repo_username =
    System.get_env("SMF_REPO_USERNAME") ||
      raise """
      environment variable SMF_REPO_USERNAME is missing.
      """

  smf_repo_password =
    System.get_env("SMF_REPO_PASSWORD") ||
      raise """
      environment variable SMF_REPO_PASSWORD is missing.
      """

  smf_repo_hostname =
    System.get_env("SMF_REPO_HOSTNAME") ||
      raise """
      environment variable SMF_REPO_HOSTNAME is missing.
      """

  smf_repo_database =
    System.get_env("SMF_REPO_DATABASE") ||
      raise """
      environment variable SMF_REPO_DATABASE is missing.
      """

  smf_repo_port =
    System.get_env("SMF_REPO_PORT") ||
      raise """
      environment variable SMF_REPO_PORT is missing.
      """

  config :epochtalk_server, EpochtalkServer.SmfRepo,
    username: smf_repo_username,
    password: smf_repo_password,
    hostname: smf_repo_hostname,
    database: smf_repo_database,
    port: smf_repo_port,
    stacktrace: true,
    show_sensitive_data_on_connection_error: false,
    pool_size: 5

  # Configure Guardian for Runtime
  config :epochtalk_server, EpochtalkServer.Auth.Guardian,
    secret_key:
      System.get_env("GUARDIAN_SECRET_KEY") ||
        raise("""
        environment variable GUARDIAN_SECRET_KEY is missing.
        You can generate one by calling: mix guardian.gen.secret
        """)

  # Configure Guardian Redis
  config :guardian_redis, :redis,
    host: System.get_env("REDIS_HOST") || "127.0.0.1",
    port: String.to_integer(System.get_env("REDIS_PORT") || "6379"),
    pool_size: String.to_integer(System.get_env("REDIS_POOL_SIZE") || "10")

  # Configure Redis for Session Storage
  config :epochtalk_server, :redix, host: System.get_env("REDIS_HOST") || "127.0.0.1"

  # Configure proxy
  config :epochtalk_server,
    proxy_config: %{
      threads_seq: System.get_env("THREADS_SEQ") || "6000000",
      boards_seq: System.get_env("BOARDS_SEQ") || "500"
    }

  # Configure frontend
  config :epochtalk_server,
    frontend_config: %{
      frontend_url: System.get_env("FRONTEND_URL") || "http://localhost:8000",
      backend_url: System.get_env("BACKEND_URL") || "http://localhost:4000",
      newbie_enabled: System.get_env("NEWBIE_ENABLED") || false,
      login_required: System.get_env("LOGIN_REQUIRED") || false,
      invite_only: System.get_env("INVITE_ONLY") || false,
      verify_registration: System.get_env("VERIFY_REGISTRATION") || true,
      post_max_length: System.get_env("POST_MAX_LENGTH") || 10_000,
      max_image_size: System.get_env("MAX_IMAGE_SIZE") || 10_485_760,
      max_avatar_size: System.get_env("MAX_AVATAR_SIZE") || 102_400,
      mobile_break_width: System.get_env("MOBILE_BREAK_WIDTH") || 767,
      ga_key: System.get_env("GA_KEY") || "UA-XXXXX-Y",
      revision: nil,
      website: %{
        title: System.get_env("WEBSITE_TITLE") || "Epochtalk Forums",
        description: System.get_env("WEBSITE_DESCRIPTION") || "Open source forum software",
        keywords:
          System.get_env("WEBSITE_KEYWORDS") || "open source, free forum, forum software, forum",
        logo: System.get_env("WEBSITE_LOGO") || nil,
        favicon: System.get_env("WEBSITE_FAVICON") || nil,
        default_avatar: System.get_env("WEBSITE_DEFAULT_AVATAR") || "/images/avatar.png",
        default_avatar_shape: System.get_env("WEBSITE_DEFAULT_AVATAR_SHAPE") || "circle"
      },
      portal: %{
        enabled: System.get_env("PORTAL_ENABLED") || false,
        board_id: System.get_env("PORTAL_BOARD_ID") || nil
      },
      emailer: %{
        ses_mode: System.get_env("EMAILER_SES_MODE") || false,
        options: %{
          from_address: System.get_env("EMAILER_OPTIONS_FROM_ADDRESS") || "info@epochtalk.com"
        }
      },
      images: %{
        s3_mode: System.get_env("IMAGES_S3_MODE") || false,
        options: %{
          local_host: System.get_env("IMAGES_OPTIONS_LOCAL_HOST") || "http://localhost:4000"
        }
      },
      rate_limiting: %{}
    }
end
