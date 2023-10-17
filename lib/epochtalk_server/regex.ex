defmodule EpochtalkServer.Regex do
  @moduledoc """
  Consolidated source for hard-coded regex patterns
  """
  @patterns %{
    username_mention: ~r/\[code\].*\[\/code\](*SKIP)(*FAIL)|(?<=^|\s)@([a-zA-Z0-9\-_.]+)/i,
    username_mention_curly: ~r/\[code\].*\[\/code\](*SKIP)(*FAIL)|{@([a-zA-Z0-9\-_.]+)}/i,
    user_id: ~r/{@^[[:digit:]]+}/
  }

  @doc """
  Given a pattern specification atom
  Returns regex pattern or nil if pattern does not exist
  """
  @spec pattern(pattern :: atom) :: Regex.t() | nil
  def pattern(pattern), do: @patterns[pattern]
end
