defmodule EpochtalkServerWeb.Helpers.Sanitize do
  @moduledoc """
  Helper for sanitizing `User` input from the front end client
  """

  @doc """
  Used to sanitize html and entities from `Thread` or `Post` title

  ## Example
      iex> alias EpochtalkServerWeb.Helpers.Sanitize
      iex> attrs = %{"title" => "&nbsp;<strong>Hello World</strong><br /><script></script><a href='google.com'></a>"}
      iex> Sanitize.html_and_entities_from_title(attrs)
      %{"title" => "&#38;nbsp;&lt;strong&gt;Hello World&lt;/strong&gt;&lt;br /&gt;&lt;script&gt;&lt;/script&gt;&lt;a href='google.com'&gt;&lt;/a&gt;"}
  """
  @spec html_and_entities_from_title(attrs :: map) :: map()
  def html_and_entities_from_title(attrs) when is_map(attrs) do
    sanitized_title =
      attrs["title"]
      |> String.replace(~r/(?:&)/, "&#38;")
      |> String.replace(~r/(?:<)/, "&lt;")
      |> String.replace(~r/(?:>)/, "&gt;")

    Map.put(attrs, "title", sanitized_title)
  end

  @doc """
  Used to sanitize html and entities from `Message` subject

  ## Example
      iex> alias EpochtalkServerWeb.Helpers.Sanitize
      iex> attrs = %{"subject" => "&nbsp;<strong>Hello World</strong><br /><script></script><a href='google.com'></a>"}
      iex> Sanitize.html_and_entities_from_subject(attrs)
      %{"subject" => "&#38;nbsp;&lt;strong&gt;Hello World&lt;/strong&gt;&lt;br /&gt;&lt;script&gt;&lt;/script&gt;&lt;a href='google.com'&gt;&lt;/a&gt;"}
  """
  @spec html_and_entities_from_subject(attrs :: map) :: map()
  def html_and_entities_from_subject(attrs) when is_map(attrs) do
    sanitized_subject =
      attrs["subject"]
      |> String.replace(~r/(?:&)/, "&#38;")
      |> String.replace(~r/(?:<)/, "&lt;")
      |> String.replace(~r/(?:>)/, "&gt;")

    Map.put(attrs, "subject", sanitized_subject)
  end

  @doc """
  Used to sanitize html and entities from `Thread` or `Post` body, store sanitized body in `body_html`
    ## Example
      iex> alias EpochtalkServerWeb.Helpers.Sanitize
      iex> attrs = %{"body" => "<i>Hey <b>this</b> is</i><br /> <h1><script>a</script></h1> <a href='google.com'>post</a> &nbsp;"}
      iex> Sanitize.html_and_entities_from_body(attrs)
      %{"body" => "<i>Hey <b>this</b> is</i><br /> <h1><script>a</script></h1> <a href='google.com'>post</a> &nbsp;", "body_html" => "&lt;i>Hey &lt;b>this&lt;/b> is&lt;/i>&lt;br /> &lt;h1>&lt;script>a&lt;/script>&lt;/h1> &lt;a href='google.com'>post&lt;/a> &#38;nbsp;"}
  """
  @spec html_and_entities_from_body(attrs :: map) :: map()
  def html_and_entities_from_body(attrs) when is_map(attrs) do
    sanitized_body =
      attrs["body"]
      |> String.replace(~r/(?:&)/, "&#38;")
      |> String.replace(~r/(?:<)/, "&lt;")

    Map.put(attrs, "body_html", sanitized_body)
  end
end
