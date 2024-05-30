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

  @doc """
  Used to parse markdown inorder to preview `Thread` or `Post` content from the frontend client
  """
  @spec markdown_within_body(to_parse :: String.t()) :: String.t()
  def markdown(to_parse) when is_binary(to_parse),
    do: Earmark.as_html!(to_parse)
end
