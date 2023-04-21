defmodule EpochtalkServerWeb.ErrorHelpers do
  use Phoenix.Controller
  alias EpochtalkServerWeb.ErrorView

  @moduledoc """
  Conveniences for translating and building error messages.
  """

  @doc """
  Renders error json from error data which could be a message or changeset errors.
  """
  def render_json_error(conn, status, %Ecto.Changeset{} = changeset) do
    render_json_error(conn, status, changeset_error_to_string(changeset))
  end

  def render_json_error(conn, status, message) do
    conn
    |> put_status(status)
    |> put_view(ErrorView)
    |> render("#{status}.json", message: message)
  end

  @doc """
  Translates changeset errors to string message.
  """
  def changeset_error_to_string(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        case value do
          # special case, handle ecto enum type
          {:parameterized, Ecto.Enum, _} -> acc
          # otherwise process as normal
          _ -> String.replace(acc, "%{#{key}}", _to_string(value))
        end
      end)
    end)
    |> Enum.reduce("", fn {k, v}, acc ->
      joined_errors = Enum.join(v, "; ")

      if String.length(acc) < 1,
        do: String.capitalize("#{k}") <> " #{joined_errors}",
        else: "#{acc}, #{k} #{joined_errors}"
    end)
  end

  def changeset_error_to_string(changeset), do: changeset

  defp _to_string(val) when is_list(val), do: Enum.join(val, ",")
  defp _to_string(val), do: to_string(val)
end
