defmodule EpochtalkServerWeb.UserView do
  use EpochtalkServerWeb, :view
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.User
  @moduledoc """
  Renders and formats `User` data, in JSON format for frontend
  """

  @doc """
  Renders formatted user JSON. Takes in a `User` with all associations preloaded
  and outputs formatted user json used for auth. Masks all user's roles to generate
  correct permissions set.
  """
  def render("user.json", %{user: user, token: token}), do: format_user_reply(user, token)

  @doc """
  Renders formatted JSON response for registration confirmation.
  ## Example
    iex> EpochtalkServerWeb.UserView.render("register_with_verify.json", %{user: %User{ username: "Test" }})
    %{
      username: "Test",
      confirm_token: true,
      message: "Successfully registered, please confirm account to login."
    }
  """
  def render("register_with_verify.json", %{user: user}) do
    %{
      username: user.username,
      confirm_token: true,
      message: "Successfully registered, please confirm account to login."
    }
  end

  @doc """
  Renders formatted JSON response for user preferences.
  ## Example
    iex> EpochtalkServerWeb.UserView.render("preferences.json", %{preferences: nil})
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
    iex> EpochtalkServerWeb.UserView.render("preferences.json", %{preferences: preferences})
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

  @doc """
  Renders whatever data it is passed when template not found. Data pass through
  for rendering misc responses (ex: {found: true} or {success: true})
  ## Example
      iex> EpochtalkServerWeb.UserView.render("DoesNotExist.json", data: %{found: true})
      %{found: true}
      iex> EpochtalkServerWeb.UserView.render("DoesNotExist.json", data: %{success: true})
      %{success: true}
  """
  def template_not_found(_template, %{conn: %{ assigns: %{ data: data }}}), do: data
  def template_not_found(_template, %{ data: data }), do: data

  # Format reply - from Models.User (login, register)
  defp format_user_reply(%User{} = user, token) do
    avatar = if user.profile, do: user.profile.avatar, else: nil
    moderating = if length(user.moderating) != 0, do: Enum.map(user.moderating, &(&1.board_id)), else: nil
    ban_expiration = if user.ban_info, do: user.ban_info.expiration, else: nil
    malicious_score = if user.malicious_score, do: user.malicious_score, else: nil
    format_user_reply(user, token, {avatar, moderating, ban_expiration, malicious_score})
  end
  # Format reply - from user stored by Guardian (authenticate)
  defp format_user_reply(user, token) do
    avatar = Map.get(user, :avatar)
    moderating = if Map.get(user, :moderating) && length(user.moderating) != 0, do: user.moderating, else: nil
    ban_expiration = Map.get(user, :ban_expiration)
    malicious_score = Map.get(user, :malicious_score)
    format_user_reply(user, token, {avatar, moderating, ban_expiration, malicious_score})
  end
  # Format reply - common user formatting functionality, outputs user reply map
  defp format_user_reply(user, token, {avatar, moderating, ban_expiration, malicious_score}) do
    reply = %{
      token: token,
      id: user.id,
      username: user.username,
      permissions: Role.get_masked_permissions(user.roles),
      roles: Enum.map(user.roles, &(&1.lookup))
    }
    # only append avatar, moderating, ban_expiration and malicious_score if present
    reply = if avatar, do: Map.put(reply, :avatar, avatar), else: reply
    reply = if moderating, do: Map.put(reply, :moderating, moderating), else: reply
    reply = if ban_expiration, do: Map.put(reply, :ban_expiration, ban_expiration), else: reply
    reply = if malicious_score, do: Map.put(reply, :malicious_score, malicious_score), else: reply
    reply
  end
end
