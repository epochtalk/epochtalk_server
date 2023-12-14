defmodule EpochtalkServerWeb.Helpers.Parse do
  @moduledoc """
  Helper for parsing `User` input from the front end client
  """

  @doc """
  Used to parse markdown within `Thread` or `Post` body, assumes
  """
  @spec markdown_within_body(attrs :: map) :: map()
  def markdown_within_body(attrs) when is_map(attrs),
    do: Map.put(attrs, "body_html", Earmark.as_html!(attrs["body_html"] || attrs["body"]))
end
