defmodule EpochtalkServerWeb.Helpers.Sanitize do
  @moduledoc """
  Helper for sanitizing `User` input from the front end client
  """

  @doc """
  Used to sanitize html from `Thread` or `Post` title

  ## Example
      iex> alias EpochtalkServerWeb.Helpers.Sanitize
      iex> attrs = %{"title" => "<strong>Hello World</strong><br /><script></script><a href='google.com'></a>"}
      iex> Sanitize.html_from_title(attrs["title"], attrs)
      %{"title" => "Hello World"}
  """
  @spec html_from_title(title :: String.t(), attrs :: map) :: map()
  def html_from_title(title, attrs) when is_binary(title) and is_map(attrs),
    do: Map.put(attrs, "title", HtmlSanitizeEx.strip_tags(title))

  @doc """
  Used to sanitize html from `Message` subject

  ## Example
      iex> alias EpochtalkServerWeb.Helpers.Sanitize
      iex> attrs = %{"subject" => "<strong>Hey this is</strong><br /> <script>a</script> <a href='google.com'>message</a>"}
      iex> Sanitize.html_from_subject(attrs["subject"], attrs)
      %{"subject" => "Hey this is a message"}
  """
  @spec html_from_subject(subject :: String.t(), attrs :: map) :: map()
  def html_from_subject(subject, attrs) when is_binary(subject) and is_map(attrs),
    do: Map.put(attrs, "subject", HtmlSanitizeEx.strip_tags(subject))

  @doc """
  Used to sanitize all html except basic formatting html from `Thread` or `Post` body
    ## Example
      iex> alias EpochtalkServerWeb.Helpers.Sanitize
      iex> attrs = %{"body" => "<i>Hey <b>this</b> is</i><br /> <h1><script>a</script></h1> <a href='google.com'>post</a>"}
      iex> Sanitize.html_from_body(attrs["body"], attrs)
      %{"body" => "<i>Hey <b>this</b> is</i><br /> <h1>a</h1> <a href=\\"google.com\\">post</a>"}
  """
  @spec html_from_body(body :: String.t(), attrs :: map) :: map()
  def html_from_body(body, attrs) when is_binary(body) and is_map(attrs),
    do: Map.put(attrs, "body", HtmlSanitizeEx.basic_html(body))
end
