defmodule EpochtalkServerWeb.Controllers.ConfigurationJS do
  use EpochtalkServerWeb, :js

  @moduledoc """
  Used to render `Configuration` related *.js.eex templates
  """

  embed_templates "templates/configuration_js/*", ext: ".js"
end
