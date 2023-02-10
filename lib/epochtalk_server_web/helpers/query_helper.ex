defmodule EpochtalkServerWeb.Helpers.QueryHelper do
  @moduledoc """
  Helper for creating dynamic queries
  """

  import Ecto.Query

  @spec build_and(Ecto.Query.t(), atom | binary, binary | number | map) ::
          Ecto.Query.t()
  def build_and(conditions, field, value) do
    condition = build_condition(field, value)
    dynamic([c], ^condition and ^conditions)
  end

  @spec build_or(Ecto.Query.t(), atom | binary, binary | number | map) ::
          Ecto.Query.t()
  def build_or(conditions, field, value) do
    condition = build_condition(field, value)
    dynamic([c], ^condition or ^conditions)
  end

  @spec sort(Ecto.Query.t(), map) :: Ecto.Query.t()
  def sort(query, input) do
    input
    |> Enum.reverse()
    |> Enum.reduce(query, fn {field, direction}, query ->
      field = String.to_existing_atom(field)
      direction = if direction == -1, do: :desc, else: :asc

      order_by(query, [c], [{^direction, field(c, ^field)}])
    end)
  end

  defp build_condition(field, input) when is_binary(field),
    do: build_condition(String.to_existing_atom(field), input)

  defp build_condition(field, %{">" => value}),
    do: dynamic([c], field(c, ^field) > ^value)

  defp build_condition(field, %{">=" => value}),
    do: dynamic([c], field(c, ^field) >= ^value)

  defp build_condition(field, %{"<" => value}),
    do: dynamic([c], field(c, ^field) < ^value)

  defp build_condition(field, %{"<=" => value}),
    do: dynamic([c], field(c, ^field) <= ^value)

  defp build_condition(field, %{"like" => value}),
    do: dynamic([c], ilike(field(c, ^field), ^value))

  defp build_condition(field, %{"in" => value}) when is_list(value),
    do: dynamic([c], field(c, ^field) in ^value)

  defp build_condition(field, value) when value in [nil],
    do: dynamic([c], is_nil(field(c, ^field)))

  defp build_condition(field, value) when is_binary(value) or is_number(value),
    do: dynamic([c], field(c, ^field) == ^value)

  defp build_condition(field, value),
    do: raise(~s{Unsupported filter "#{field}": "#{inspect(value)}"})
end
