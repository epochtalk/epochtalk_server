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
      order_by: [desc: t.id_last_msg],
      select: %{
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
        post_count: t.numReplies
      }
    )
    |> ProxyPagination.page_simple(count_query, page, per_page: per_page)
    |> case do
      {:ok, [], _} ->
        {:error, "Threads not found for board_id: #{id}"}

      {:ok, threads, data} ->
        threads =
          Enum.reduce(threads, [], fn thread, acc ->
            first_post = get_post(thread.first_post_id)
            last_post = get_post(thread.last_post_id)

            thread =
              thread
              |> Map.put(:title, first_post.title)
              |> Map.put(:user_id, first_post.user_id)
              |> Map.put(:username, first_post.username)
              |> Map.put(:user_deleted, false)
              |> Map.put(:last_post_id, last_post.id)
              |> Map.put(:last_post_created_at, last_post.created_at * 1000)
              |> Map.put(:last_post_deleted, false)
              |> Map.put(:last_post_user_id, last_post.user_id)
              |> Map.put(:last_post_username, last_post.username)
              |> Map.put(:last_post_user_deleted, false)
              |> Map.put(:last_viewed, nil)
              |> Map.put(:created_at, first_post.created_at * 1000)
              |> Map.put(:is_proxy, true)

            [thread | acc]
          end)

        return_tuple(Enum.reverse(threads), data)
    end
  end

  def build_threads(ids) do
    %{id_board_blacklist: id_board_blacklist} = Application.get_env(:epochtalk_server, :proxy_config)
    from(t in "smf_topics",
      limit: ^length(ids),
      where: t.id_topic in ^ids and t.id_board not in ^id_board_blacklist,
      select: %{
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
        post_count: t.numReplies
      }
    )
    |> SmfRepo.all()
    |> case do
      [] ->
        {:error, "Threads not found for ids: #{ids}"}

      threads ->
        threads =
          Enum.reduce(threads, [], fn thread, acc ->
            first_post = get_post(thread.first_post_id)
            last_post = get_post(thread.last_post_id)

            thread =
              thread
              |> Map.put(:title, first_post.title)
              |> Map.put(:user_id, first_post.user_id)
              |> Map.put(:username, first_post.username)
              |> Map.put(:user_deleted, false)
              |> Map.put(:last_post_id, last_post.id)
              |> Map.put(:last_post_created_at, last_post.created_at * 1000)
              |> Map.put(:last_post_deleted, false)
              |> Map.put(:last_post_user_id, last_post.user_id)
              |> Map.put(:last_post_username, last_post.username)
              |> Map.put(:last_post_user_deleted, false)
              |> Map.put(:last_viewed, nil)
              |> Map.put(:created_at, first_post.created_at * 1000)

            [thread | acc]
          end)

        return_tuple(Enum.reverse(threads))
    end
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
      limit: 15,
      where: m.id_topic == ^id and m.id_board not in ^id_board_blacklist,
      order_by: [asc: m.posterTime],
      select: %{
        id: m.id_msg,
        thread_id: m.id_topic,
        board_id: m.id_board,
        user_id: m.id_member,
        title: m.subject,
        body: m.body,
        updated_at: m.modifiedTime,
        username: m.posterName,
        poster_time: m.posterTime,
        poster_name: m.posterName,
        modified_time: m.modifiedTime
      }
    )
    |> ProxyPagination.page_simple(count_query, page, per_page: per_page)
    |> case do
      {:ok, [], _} ->
        {:error, "Posts not found for thread_id: #{id}"}

      {:ok, posts, data} ->
        posts =
          Enum.reduce(posts, [], fn post, acc ->
            post =
              post
              |> Map.put(:created_at, post.poster_time * 1000)
              |> Map.delete(:poster_time)

            [post | acc]
          end)

        return_tuple(Enum.reverse(posts), data)
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

  defp get_post(id) do
    %{id_board_blacklist: id_board_blacklist} = Application.get_env(:epochtalk_server, :proxy_config)
    from(m in "smf_messages",
      limit: 1,
      where: m.id_msg == ^id and m.id_board not in ^id_board_blacklist,
      select: %{
        id: m.id_msg,
        thread_id: m.id_topic,
        board_id: m.id_board,
        user_id: m.id_member,
        title: m.subject,
        body: m.body,
        username: m.posterName,
        created_at: m.posterTime,
        modified_time: m.modifiedTime
      }
    )
    |> SmfRepo.one()
    |> case do
      nil ->
        {:error, "Post not found for id: #{id}"}

      post ->
        post
    end
  end
end
