defmodule EpochtalkServerWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  @doc """
  Translates changeset errors to string message.
  """
  def changeset_error_to_string(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", _to_string(value))
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
