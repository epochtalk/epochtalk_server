defmodule EpochtalkServerWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use EpochtalkServerWeb, :controller
      use EpochtalkServerWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json, :js],
        layouts: [html: EpochtalkServerWeb.Layouts]

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def js do
    quote do
      import EpochtalkServerWeb, only: [embed_templates: 2]

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: EpochtalkServerWeb.Endpoint,
        router: EpochtalkServerWeb.Router,
        statics: EpochtalkServerWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro embed_templates(pattern, opts) do
    quote do
      require Phoenix.Template

      Phoenix.Template.compile_all(
        &(&1 |> Path.basename() |> Path.rootname() |> Path.rootname()),
        Path.expand(unquote(opts)[:root] || __DIR__, __DIR__),
        unquote(pattern) <> unquote(opts)[:ext]
      )
    end
  end
end
