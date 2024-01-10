defmodule EpochtalkServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  @env Mix.env()

  @impl true
  def start(_type, _args) do
    # Set Environment to config
    # Work around for dialyzer rendering @env as :dev
    Application.put_env(:epochtalk_server, :env, @env)

    children = [
      # Start Guardian Redis Redix connection
      GuardianRedis.Redix,
      # Start the server Redis connection
      {Redix, host: redix_config()[:host], name: redix_config()[:name]},
      # Start the Ecto repository
      EpochtalkServer.Repo,
      # Start the Smf repository
      EpochtalkServer.SmfRepo,
      # Start Role Cache
      EpochtalkServer.Cache.Role,
      # Warm frontend_config variable (referenced by api controllers)
      # This task starts, does its thing and dies
      {Task, &EpochtalkServer.Models.Configuration.warm_frontend_config/0},
      # Start the Telemetry supervisor
      EpochtalkServerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: EpochtalkServer.PubSub},
      # Start Finch
      {Finch, name: EpochtalkServer.Finch},
      # Start Presence for Phoenix channel tracking
      EpochtalkServerWeb.Presence,
      # Start the Endpoint (http/https)
      EpochtalkServerWeb.Endpoint
      # Start a worker by calling: EpochtalkServer.Worker.start_link(arg)
      # {EpochtalkServer.Worker, arg}
    ]

    # don't run config_warmer during tests
    children =
      if Application.get_env(:epochtalk_server, :env) == :test,
        do:
          List.delete(
            children,
            {Task, &EpochtalkServer.Models.Configuration.warm_frontend_config/0}
          ),
        else: children

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EpochtalkServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EpochtalkServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # fetch redix config
  defp redix_config(), do: Application.get_env(:epochtalk_server, :redix)
end
