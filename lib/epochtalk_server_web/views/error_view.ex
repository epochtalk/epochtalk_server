defmodule EpochtalkServerWeb.ErrorView do
  use EpochtalkServerWeb, :view

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def template_not_found(template, assigns) do
    %{
      status: assigns.status,
      message: assigns.reason.message,
      error: Phoenix.Controller.status_message_from_template(template)
    }
  end
end
