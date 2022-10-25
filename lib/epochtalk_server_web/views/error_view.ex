defmodule EpochtalkServerWeb.ErrorView do
  @moduledoc """
  Renders and formats error data, in JSON format for frontend
  """
  use EpochtalkServerWeb, :view

  @doc """
  Render uses `template_not_found` when Phoenix cannot find the specified template, this
  has been modified to handle and all types of errors. Epochtalk Server sends all errors
  through this view to render a consistent error JSON.

  ## Example
      iex> EpochtalkServerWeb.ErrorView.render("500.json")
      %{error: "Internal Server Error", message: "Request Error", status: 500}
      iex> EpochtalkServerWeb.ErrorView.render("400.json")
      %{error: "Bad Request", message: "Request Error", status: 400}
      iex> EpochtalkServerWeb.ErrorView.render("404.json")
      %{error: "Not Found", message: "Request Error", status: 404}
      iex> EpochtalkServerWeb.ErrorView.render("401.json")
      %{error: "Unauthorized", message: "Request Error", status: 401}
      iex> EpochtalkServerWeb.ErrorView.template_not_found("DoesNotExist.json", %{message: "Custom Error Message", status: 500})
      %{error: "Internal Server Error", message: "Custom Error Message", status: 500}
      iex> EpochtalkServerWeb.ErrorView.template_not_found("DoesNotExist.json", %{message: "Custom Error Message", status: 404})
      %{error: "Not Found", message: "Custom Error Message", status: 404}
  """
  def template_not_found(template, assigns), do: format_error(template, assigns)

  # match assigns.reason.message and assigns.conn.status
  defp format_error(_template, %{reason: %{message: message}, conn: %{status: status}}), do: format_error(status, message)
  # match assigns.reason.message and assigns.status
  defp format_error(_template, %{reason: %{message: message}, status: status}), do: format_error(status, message)
  # match assigns.message and assigns.conn.status
  defp format_error(_template, %{message: message, conn: %{status: status}}), do: format_error(status, message)
  # match assigns.message and assigns.status
  defp format_error(_template, %{message: message, status: status}), do: format_error(status, message)
  # match stack and status (Ex: function error from redis in session)
  defp format_error(_template, %{stack: _, status: status}), do: format_error(status, "Something went wrong")
  # match assigns.reason.message and assigns.conn.status
  defp format_error(_template, %{reason: %{message: message}, conn: %{status: status}}), do: format_error(status, message)
  # match missing template with no assigns, handles render("404.json") etc
  defp format_error(template, %{__phx_template_not_found__: _}) do
    [potential_status | _] = String.split(template, ".json")
    case Integer.parse(potential_status) do
      {status, ""} -> format_error(status, "Request Error") # render error wtih status
      _ -> format_error(500, "Request Error") # 500 if cannot render template
    end
  end
  # format errors with readable message
  defp format_error(status, message) when is_integer(status) and is_binary(message) do
    %{
      status: status,
      message: message,
      error: Phoenix.Controller.status_message_from_template(to_string(status))
    }
  end
  # format errors with unknown error
  defp format_error(status, _data), do: format_error(status, "Something went wrong")
end
