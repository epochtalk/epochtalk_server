defmodule EpochtalkServerWeb.PreferenceView do
  use EpochtalkServerWeb, :view

  @moduledoc """
  Renders and formats `Preference` data, in JSON format for frontend
  """

  @doc """
  Renders formatted JSON response for user preferences.
  ## Example
    iex> EpochtalkServerWeb.PreferenceView.render("preferences.json", %{preferences: nil})
    %{
      posts_per_page: 25,
      threads_per_page: 25,
      collapsed_categories: [],
      ignored_boards: [],
      timezone_offset: "",
      notify_replied_threads: true,
      ignore_newbies: false,
      patroller_view: false,
      email_mentions: true,
      email_messages: true
    }
    iex> preferences = %{
    iex>   posts_per_page: 25,
    iex>   threads_per_page: 25,
    iex>   collapsed_categories: %{"cats" => []},
    iex>   ignored_boards: %{"boards" => []},
    iex>   timezone_offset: "",
    iex>   notify_replied_threads: true,
    iex>   ignore_newbies: false,
    iex>   patroller_view: false,
    iex>   email_mentions: true,
    iex>   email_messages: true
    iex> }
    iex> EpochtalkServerWeb.PreferenceView.render("preferences.json", %{preferences: preferences})
  """
  def render("preferences.json", %{preferences: nil}) do
    %{
      posts_per_page: 25,
      threads_per_page: 25,
      collapsed_categories: [],
      ignored_boards: [],
      timezone_offset: "",
      notify_replied_threads: true,
      ignore_newbies: false,
      patroller_view: false,
      email_mentions: true,
      email_messages: true
    }
  end

  def render("preferences.json", %{preferences: preferences}) do
    %{
      posts_per_page: preferences.posts_per_page,
      threads_per_page: preferences.threads_per_page,
      collapsed_categories: preferences.collapsed_categories["cats"],
      ignored_boards: preferences.ignored_boards["boards"],
      timezone_offset: preferences.timezone_offset,
      notify_replied_threads: preferences.notify_replied_threads,
      ignore_newbies: preferences.ignore_newbies,
      patroller_view: preferences.patroller_view,
      email_mentions: preferences.email_mentions,
      email_messages: preferences.email_messages
    }
  end
end
