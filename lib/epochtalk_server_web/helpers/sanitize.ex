defmodule EpochtalkServerWeb.Helpers.Sanitize do
  @moduledoc """
  Helper for sanitizing `User` input from the front end client
  """

  @doc """
  Used to strip html from `Thread` and `Post` title
  """
  @spec strip_html_from_title(title :: String.t(), attrs :: map) :: map()
  def strip_html_from_title(title, attrs) when is_binary(title) and is_map(attrs),
    do: Map.put(attrs, "title", HtmlSanitizeEx.strip_tags(title))
end
