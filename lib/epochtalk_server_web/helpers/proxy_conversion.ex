defmodule EpochtalkServerWeb.Helpers.ProxyConversion do
  import Ecto.Query
  alias EpochtalkServer.SmfRepo
  alias EpochtalkServerWeb.Helpers.ProxyPagination

  @moduledoc """
  Helper for pulling and formatting data from SmfRepo
  """

  def build_model(model_type, ids, _, _) when is_nil(model_type) or is_nil(ids) do
    {:ok, %{}, %{}}
  end

  def build_model(_, ids, _, _) when length(ids) > 25 do
    {:error, "Limit too large, please try again"}
  end

  def build_model(model_type, id, page, per_page) when is_integer(id) do
    case model_type do
      "threads.by_board" ->
        build_threads_by_board(id, page, per_page)

      "posts.by_thread" ->
        build_posts_by_thread(id, page, per_page)

      _ ->
        build_model(model_type, [id], nil, nil)
    end
  end

  def build_model(model_type, ids, _, _) do
    case model_type do
      "category" ->
        build_categories(ids)

      "board" ->
        build_boards(ids)

      "thread" ->
        build_threads(ids)

      "post" ->
        build_posts(ids)

      _ ->
        build_model(nil, nil, nil, nil)
    end
  end

  def build_model(model_type, id) do
    case model_type do
      "poll.by_thread" ->
        build_poll(id)

      _ ->
        build_model(nil, nil, nil, nil)
    end
  end

  def build_model(model_type) do
    case model_type do
      "threads.recent" ->
        build_recent_threads()

      _ ->
        build_model(nil, nil, nil, nil)
    end
  end

  def build_poll(thread_id) do
    from(t in "smf_topics",
      where: t.id_topic == ^thread_id
    )
    |> join(:left, [t], p in "smf_polls", on: t.id_poll == p.id_poll)
    |> select([t, p], %{
      id: t.id_poll,
      change_vote: p.changeVote,
      display_mode: "always",
      expiration: p.expireTime * 1000,
      has_voted: false,
      locked: (p.votingLocked == 1),
      max_answers: p.maxVotes,
      question: p.question
    })
    |> SmfRepo.one()
    |> case do
      [] ->
        {:error, "Poll for thread not found"}

      poll ->
        from(t in "smf_topics",
          where: t.id_topic == ^thread_id
        )
        |> join(:left, [t], pc in "smf_poll_choices", on: t.id_poll == pc.id_poll)
        |> select([t, pc], %{
          id: pc.id_choice,
          selected: false,
          votes: pc.votes,
          answer: pc.label
        })
        |> SmfRepo.all()
        |> case do
          [] ->
            {:error, "Poll for thread not found"}

          answers ->
            if poll.id > 0, do: Map.put(poll, :answers, answers), else: nil
        end
    end
  end

  def build_recent_threads() do
    %{id_board_blacklist: id_board_blacklist} = Application.get_env(:epochtalk_server, :proxy_config)
    from(t in "smf_topics",
      limit: 5,
      where: t.id_board not in ^id_board_blacklist,
      order_by: [desc: t.id_last_msg]
    )
    |> join(:left, [t], m in "smf_messages", on: t.id_first_msg == m.id_msg)
    |> join(:left, [t], m in "smf_messages", on: t.id_last_msg == m.id_msg)
    |> join(:left, [t], b in "smf_boards", on: t.id_board == b.id_board)
    |> select([t, f, l, b], %{
      id: t.id_topic,
      slug: t.id_topic,
      board_id: t.id_board,
      board_name: b.name,
      board_slug: t.id_board,
      sticky: t.isSticky,
      locked: t.locked,
      poll: t.id_poll > 0,
      moderated: t.selfModerated,
      first_post_id: t.id_first_msg,
      last_post_id: t.id_last_msg,
      title: f.subject,
      updated_at: l.posterTime * 1000,
      last_post_created_at: l.posterTime * 1000,
      last_post_user_id: l.id_member,
      last_post_username: l.posterName,
      view_count: t.numViews,
      last_post_position: nil,
      last_post_deleted: false,
      last_post_user_deleted: false,
      new_post_id: nil,
      new_post_position: nil,
      is_proxy: true
    })
    |> SmfRepo.all()
    |> case do
      [] ->
        {:error, "Recent threads not found"}

      threads -> threads
    end
  end

  def build_categories(ids) do
    from(c in "smf_categories",
      limit: ^length(ids),
      where: c.id_cat in ^ids,
      select: %{
        id: c.id_cat,
        name: c.name,
        view_order: c.catOrder
      }
    )
    |> SmfRepo.all()
    |> case do
      [] ->
        {:error, "Categories not found for ids: #{ids}"}

      categories ->
        return_tuple(categories)
    end
  end

  def build_boards(ids) do
    %{id_board_blacklist: id_board_blacklist} = Application.get_env(:epochtalk_server, :proxy_config)
    from(b in "smf_boards",
      limit: ^length(ids),
      where: b.id_board in ^ids and b.id_board not in ^id_board_blacklist,
      select: %{
        id: b.id_board,
        slug: b.id_board,
        cat_id: b.id_cat,
        name: b.name,
        description: b.description,
        thread_count: b.numTopics,
        post_count: b.numPosts
      }
    )
    |> SmfRepo.all()
    |> case do
      [] ->
        {:error, "Boards not found for ids: #{ids}"}

      boards ->
        boards =
          Enum.map(boards, fn board ->
            board =
              board
              |> Map.put(:children, [])

            board
          end)

        return_tuple(boards)
    end
  end

  def build_threads_by_board(id, page, per_page) do
    %{id_board_blacklist: id_board_blacklist} = Application.get_env(:epochtalk_server, :proxy_config)
    count_query =
      from t in "smf_topics", where: t.id_board == ^id and t.id_board not in ^id_board_blacklist, select: %{count: count(t.id_topic)}

    from(t in "smf_topics",
      where: t.id_board == ^id and t.id_board not in ^id_board_blacklist,
      order_by: [desc: t.id_last_msg]
    )
    |> join(:left, [t], f in "smf_messages", on: t.id_first_msg == f.id_msg)
    |> join(:left, [t], l in "smf_messages", on: t.id_last_msg == l.id_msg)
    |> join(:left, [t, f, l], m in "smf_members", on: l.id_member == m.id_member)
    |> join(:left, [t, f, l, m], a in "smf_attachments",
      on: m.id_member == a.id_member and a.attachmentType == 1
    )
    |> select([t, f, l, m, a], %{
      id: t.id_topic,
      slug: t.id_topic,
      board_id: t.id_board,
      sticky: t.isSticky,
      locked: t.locked,
      view_count: t.numViews,
      first_post_id: t.id_first_msg,
      last_post_id: t.id_last_msg,
      started_user_id: t.id_member_started,
      updated_user_id: t.id_member_updated,
      moderated: t.selfModerated,
      post_count: t.numReplies,
      title: f.subject,
      user_id: f.id_member,
      username: f.posterName,
      created_at: f.posterTime * 1000,
      user_deleted: false,
      last_post_created_at: l.posterTime * 1000,
      last_post_deleted: false,
      last_post_user_id: l.id_member,
      last_post_username: l.posterName,
      last_post_user_deleted: false,
      last_post_avatar:
        fragment(
          "if(? <>'',concat('/avatars/',?),ifnull(concat('/useravatars/',?),''))",
          m.avatar,
          m.avatar,
          a.filename
        ),
      last_viewed: nil,
      is_proxy: true
    })
    |> ProxyPagination.page_simple(count_query, page, per_page: per_page)
  end

  def build_threads(ids) do
    %{id_board_blacklist: id_board_blacklist} = Application.get_env(:epochtalk_server, :proxy_config)
    from(t in "smf_topics",
      limit: ^length(ids),
      where: t.id_topic in ^ids and t.id_board not in ^id_board_blacklist
    )
    # get first and last message for thread
    |> join(:left, [t], m in "smf_messages", on: t.id_first_msg == m.id_msg)
    |> join(:left, [t], m in "smf_messages", on: t.id_last_msg == m.id_msg)
    |> select([t, f, l], %{
      id: t.id_topic,
      slug: t.id_topic,
      board_id: t.id_board,
      sticky: t.isSticky,
      locked: t.locked,
      view_count: t.numViews,
      first_post_id: t.id_first_msg,
      last_post_id: t.id_last_msg,
      started_user_id: t.id_member_started,
      updated_user_id: t.id_member_updated,
      moderated: t.selfModerated,
      post_count: t.numReplies,
      title: f.subject,
      user_id: f.id_member,
      username: f.posterName,
      created_at: f.posterTime * 1000,
      user_deleted: false,
      last_post_created_at: l.posterTime * 1000,
      last_post_deleted: false,
      last_post_user_id: l.id_member,
      last_post_username: l.posterName,
      last_post_user_deleted: false,
      last_viewed: nil
    })
    |> SmfRepo.all()
    |> return_tuple()
  end

  def build_posts(ids) do
    %{id_board_blacklist: id_board_blacklist} = Application.get_env(:epochtalk_server, :proxy_config)
    from(m in "smf_messages",
      limit: ^length(ids),
      where: m.id_msg in ^ids and m.id_board not in ^id_board_blacklist,
      select: %{
        id: m.id_msg,
        thread_id: m.id_topic,
        board_id: m.id_board,
        user_id: m.id_member,
        title: m.subject,
        body: m.body,
        updated_at: m.modifiedTime
      }
    )
    |> SmfRepo.all()
    |> case do
      [] ->
        {:error, "Posts not found for ids: #{ids}"}

      posts ->
        posts =
          Enum.reduce(posts, [], fn post, acc ->
            post =
              post
              |> Map.put(:created_at, post.poster_time * 1000)
              |> Map.delete(:poster_time)

            [post | acc]
          end)

        return_tuple(posts)
    end
  end

  def build_posts_by_thread(id, page, per_page) do
    %{id_board_blacklist: id_board_blacklist} = Application.get_env(:epochtalk_server, :proxy_config)
    count_query =
      from m in "smf_messages", where: m.id_topic == ^id and m.id_board not in ^id_board_blacklist, select: %{count: count(m.id_topic)}

    from(m in "smf_messages",
      limit: ^per_page,
      where: m.id_topic == ^id and m.id_board not in ^id_board_blacklist,
      order_by: [asc: m.id_msg]
    )
    |> join(:left, [m], u in "smf_members", on: m.id_member == u.id_member)
    |> join(:left, [m, u], a in "smf_attachments",
      on: u.id_member == a.id_member and a.attachmentType == 1
    )
    |> select([m, u, a], %{
        id: m.id_msg,
        thread_id: m.id_topic,
        board_id: m.id_board,
        title: m.subject,
        body: m.body,
        updated_at: m.modifiedTime,
        username: m.posterName,
        created_at: m.posterTime * 1000,
        modified_time: m.modifiedTime,
        avatar:
          fragment(
            "if(? <>'',concat('https://bitcointalk.org/avatars/',?),ifnull(concat('https://bitcointalk.org/useravatars/',?),''))",
            u.avatar,
            u.avatar,
            a.filename
          ),
        user: %{
          id: m.id_member,
          username: m.posterName,
          signature: u.signature,
          activity: u.activity,
          merit: u.merit,
          title: u.usertitle
        }
      }
    )
    |> ProxyPagination.page_simple(count_query, page, per_page: per_page)
    |> case do
      {:ok, [], _} ->
        {:error, "Posts not found for thread_id: #{id}"}

      {:ok, posts, data} ->
        return_tuple(posts, data)
    end
  end

  defp return_tuple(object) do
    if length(object) > 1 do
      {:ok, object}
    else
      {:ok, List.first(object)}
    end
  end

  defp return_tuple(object, data) do
    if length(object) > 1 do
      {:ok, object, data}
    else
      {:ok, List.first(object), data}
    end
  end
end
