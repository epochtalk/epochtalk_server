defmodule EpochtalkServerWeb.Helpers.Parse do
  @moduledoc """
  Helper for parsing `User` input from the front end client
  """

  @doc """
  Used to parse markdown within `Thread` or `Post` body
  """
  @spec markdown_within_body(body :: String.t(), attrs :: map) :: map()
  def markdown_within_body(body, attrs) when is_binary(body) and is_map(attrs),
    do: Map.put(attrs, "body_html", Earmark.as_html!(body))
end
