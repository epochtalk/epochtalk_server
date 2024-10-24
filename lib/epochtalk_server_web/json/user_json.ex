defmodule EpochtalkServerWeb.Controllers.UserJSON do
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
  def user(%{user: user, token: token}), do: format_user_reply(user, token)

  @doc """
  Renders formatted user JSON for find proxy
  """
  def find_proxy(%{user: user}) do
    parsed_signature =
      if user.signature do
        %Porcelain.Result{out: parsed_sig, status: _status} =
          Porcelain.shell(
            "php -r \"require 'parsing.php'; ECHO parse_bbc('" <> user.signature <> "');\""
          )

        parsed_sig
      else
        nil
      end

    user |> Map.put(:signature, parsed_signature)
  end

  @doc """
  Renders formatted user JSON for find
  """
  def find(%{
        user: user,
        activity: activity,
        metric_rank_maps: metric_rank_maps,
        ranks: ranks,
        show_hidden: show_hidden
      }) do
    highest_role = user.roles |> Enum.sort_by(& &1.priority) |> List.first()
    [post_count | _] = metric_rank_maps

    # handle missing profile/preferences row
    user = user |> Map.put(:profile, user.profile || %{})
    user = user |> Map.put(:preferences, user.preferences || %{})

    # fetch potentially nested fields
    fields = Map.get(user.profile, :fields, %{})

    ret = %{
      id: user.id,
      username: user.username,
      created_at: user.created_at,
      updated_at: user.updated_at,
      avatar: Map.get(user.profile, :avatar),
      post_count: Map.get(user.profile, :post_count),
      last_active: Map.get(user.profile, :last_active),
      dob: fields["dob"],
      name: fields["name"],
      gender: fields["gender"],
      website: fields["website"],
      language: fields["language"],
      location: fields["location"],
      role_name: Map.get(highest_role, :name),
      role_highlight_color: Map.get(highest_role, :highlight_color),
      roles: Enum.map(user.roles, & &1.lookup),
      priority: Map.get(highest_role, :priority),
      metadata: %{
        rank_metric_maps: post_count.maps,
        ranks: ranks
      },
      activity: activity
    }

    if show_hidden,
      do:
        ret
        |> Map.put(:email, user.email)
        |> Map.put(:threads_per_page, Map.get(user.preferences, :threads_per_page) || 25)
        |> Map.put(:posts_per_page, Map.get(user.preferences, :posts_per_page) || 25)
        |> Map.put(:ignored_boards, Map.get(user.preferences, :ignored_boards) || [])
        |> Map.put(:collapsed_categories, Map.get(user.preferences, :collapsed_categories) || []),
      else: ret
  end

  @doc """
  Renders formatted JSON response for registration confirmation.
  ## Example
    iex> EpochtalkServerWeb.Controllers.UserJSON.register_with_verify(%{user: %User{ username: "Test" }})
    %{
      username: "Test",
      confirm_token: true,
      message: "Successfully registered, please confirm account to login."
    }
  """
  def register_with_verify(%{user: user}) do
    %{
      username: user.username,
      confirm_token: true,
      message: "Successfully registered, please confirm account to login."
    }
  end

  @doc """
  Renders whatever data it is passed when template not found. Data pass through
  for rendering misc responses (ex: {found: true} or {success: true})
  ## Example
      iex> EpochtalkServerWeb.Controllers.UserJSON.data(%{data: %{found: true}})
      %{found: true}
      iex> EpochtalkServerWeb.Controllers.UserJSON.data(%{data: %{success: true}})
      %{success: true}
  """
  def data(%{conn: %{assigns: %{data: data}}}), do: data
  def data(%{data: data}), do: data

  # Format reply - from Models.User (login, register)
  defp format_user_reply(%User{} = user, token) do
    avatar = if user.profile, do: user.profile.avatar, else: nil

    moderating =
      if length(user.moderating) != 0, do: Enum.map(user.moderating, & &1.board_id), else: nil

    ban_expiration = if user.ban_info, do: user.ban_info.expiration, else: nil
    malicious_score = if user.malicious_score, do: user.malicious_score, else: nil
    format_user_reply(user, token, {avatar, moderating, ban_expiration, malicious_score})
  end

  # Format reply - from user stored by Guardian (authenticate)
  defp format_user_reply(user, token) do
    avatar = Map.get(user, :avatar)

    moderating =
      if Map.get(user, :moderating) && length(user.moderating) != 0,
        do: user.moderating,
        else: nil

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
      roles: Enum.map(user.roles, & &1.lookup)
    }

    # only append avatar, moderating, ban_expiration and malicious_score if present
    reply = if avatar, do: Map.put(reply, :avatar, avatar), else: reply
    reply = if moderating, do: Map.put(reply, :moderating, moderating), else: reply
    reply = if ban_expiration, do: Map.put(reply, :ban_expiration, ban_expiration), else: reply
    reply = if malicious_score, do: Map.put(reply, :malicious_score, malicious_score), else: reply
    reply
  end
end
