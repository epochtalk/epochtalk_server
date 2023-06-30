defmodule EpochtalkServerWeb.Controllers.MentionJSON do
  @moduledoc """
  Renders and formats `User` data, in JSON format for frontend
  """

  @doc """
  Renders paginated `User` mentions. If extended is true returns additional `Board` and `Post` details.
  """
  def page(%{
        mentions: mentions,
        pagination_data: %{page: page, limit: limit, next: next, prev: prev},
        extended: extended
      }) do
    mentions =
      Enum.reduce(mentions, [], fn m, acc ->
        formatted_mention = %{
          created_at: m.created_at,
          id: m.id,
          mentioner: m.mentioner.username,
          mentioner_avatar: if(m.mentioner.profile, do: m.mentioner.profile.avatar, else: nil),
          notification_id: m.notification_id,
          post_id: m.post.id,
          post_start: m.post.position,
          thread_id: m.thread_id,
          thread_slug: m.thread.slug,
          title: m.post.content["title"],
          viewed: m.viewed
        }

        if extended,
          do: [
            formatted_mention
            |> Map.put(:body_html, m.post.content["body_html"] || m.post.content["body"])
            |> Map.put(:board_name, m.thread.board.name)
            |> Map.put(:board_id, m.thread.board_id)
            | acc
          ],
          # prepend to accumulator list
          else: [formatted_mention | acc]
      end)
      # reverse, because of prepend to accumulator
      |> Enum.reverse()

    result = %{
      data: mentions,
      next: next,
      prev: prev,
      page: page,
      limit: limit
    }

    if extended, do: Map.put(result, :extended, extended), else: result
  end
end
