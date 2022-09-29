defmodule EpochtalkServerWeb.ErrorView do
  use EpochtalkServerWeb, :view

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def template_not_found(_template, assigns) do
    format_error(assigns)
  end

  # match assigns.reason.message and assigns.conn.status
  defp format_error(%{reason: %{message: message}, conn: %{status: status}}), do: format_error(status, message)
  # match assigns.reason.message and assigns.status
  defp format_error(%{reason: %{message: message}, status: status}), do: format_error(status, message)
  # match assigns.message and assigns.conn.status
  defp format_error(%{message: message, conn: %{status: status}}), do: format_error(status, message)
  # match assigns.message and assigns.status
  defp format_error(%{message: message, status: status}), do: format_error(status, message)
  # match stack and status (Ex: function error from redis in session)
  defp format_error(%{stack: stack, status: status}) do
    format_error(status, "Something went wrong")
  end

  defp format_error(status, message) when is_binary(message) do
    %{
      status: status,
      message: message,
      error: Phoenix.Controller.status_message_from_template(to_string(status))
    }
  end
end
