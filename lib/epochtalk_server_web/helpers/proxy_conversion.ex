defmodule EpochtalkServerWeb.Helpers.ProxyConversion do
  use GenServer
  import Ecto.Query
  alias EpochtalkServer.SmfRepo
  alias EpochtalkServer.ProxySupervisor

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    {:ok, opts}
  end

  def build_model(model_type, ids) when is_nil(model_type) or is_nil(ids) do
    {:ok, %{}}
  end

  def build_model(_, ids) when length(ids) > 10 do
    {:error, "Limit too large, please try again"}
  end

  def build_model(model_type, id) when is_integer(id) do
    ProxySupervisor.start_link([])

    case model_type do
      "threads.by_board" ->
        build_thread_model_by_board(id)
      "posts.by_thread" ->
        build_post_model_by_thread(id)
      _ ->
        build_model(model_type, [id])
    end
  end

  def build_model(model_type, ids) do
    ProxySupervisor.start_link([])

    case model_type do
      "category" ->
        build_category_model(ids)

      "board" ->
        build_board_model(ids)

      "thread" ->
        build_thread_model(ids)

      "post" ->
        build_post_model(ids)

      _ ->
        build_model(nil, nil)
    end
  end

  def build_category_model(ids) do
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

  def build_board_model(ids) do
    from(b in "smf_boards",
      limit: ^length(ids),
      where: b.id_board in ^ids,
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
          end)

        return_tuple(boards)
    end
  end

  def build_thread_model_by_board(id) do
    from(t in "smf_topics",
      limit: 10,
      where: t.id_board == ^id,
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
    |> SmfRepo.all()
    |> case do
      [] ->
        {:error, "Threads not found for board_id: #{id}"}

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
              |> Map.put(:last_post_avatar, last_post.avatar)
              |> Map.put(:last_viewed, nil)
              |> Map.put(:created_at, first_post.created_at * 1000)

            acc = [thread | acc]
            acc
          end)

        return_tuple(Enum.reverse(threads))
    end
  end

  def build_thread_model(ids) do
    from(t in "smf_topics",
      limit: ^length(ids),
      where: t.id_topic in ^ids,
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
              |> Map.put(:last_post_avatar, last_post.avatar)
              |> Map.put(:last_viewed, nil)
              |> Map.put(:created_at, first_post.created_at * 1000)

            acc = [thread | acc]
            acc
          end)

        return_tuple(Enum.reverse(threads))
      end
  end

  def build_post_model(ids) do
    from(m in "smf_messages",
      limit: ^length(ids),
      where: m.id_msg in ^ids,
      select: %{
        id: m.id_msg,
        thread_id: m.id_topic,
        board_id: m.id_board,
        user_id: m.id_member,
        title: m.subject,
        body: m.body,
        updated_at: m.modifiedTime,
        avatar: m.icon
      }
    )
    |> SmfRepo.all()
    |> case do
      [] ->
        {:error, "Posts not found for ids: #{ids}"}

      posts ->
        posts =
          Enum.map(posts, fn post ->
            post = if post.thread_id, do: build_post_and_thread_mapping(post)
            post
          end)

        return_tuple(posts)
    end
  end

  def build_post_model_by_thread(id) do
    from(m in "smf_messages",
      limit: 10,
      where: m.id_topic == ^id,
      order_by: [desc: m.posterTime],
      select: %{
        id: m.id_msg,
        thread_id: m.id_topic,
        board_id: m.id_board,
        user_id: m.id_member,
        title: m.subject,
        body: m.body,
        updated_at: m.modifiedTime,
        avatar: m.icon,
        username: m.posterName,
        user_email: m.posterEmail,
        poster_time: m.posterTime,
        poster_name: m.posterName,
        modified_time: m.modifiedTime
      }
    )
    |> SmfRepo.all()
    |> case do
      [] ->
        {:error, "Posts not found for thread_id: #{id}"}

      posts ->
        posts =
          Enum.reduce(posts, [], fn post, acc ->
            post =
              post
              |> Map.put(:created_at, post.poster_time * 1000)
              |> Map.delete(:poster_time)

            acc = [post | acc]
            acc
          end)

        return_tuple(posts)
    end
  end

  defp build_category_and_board_mapping(board) do
    {:ok, category} = build_category_model([board.cat_id])

    board =
      board
      |> Map.put(:category, category)
      |> Map.put(:board_mapping, build_board_mapping(category, board))
      |> Map.delete(:cat_id)

    board
  end

  def build_thread_and_board_mapping(thread) do
    {:ok, board} = build_board_model([thread.board_id])

    thread =
      thread
      |> Map.put(:board, board)
      |> Map.delete(:board_id)

    thread
  end

  defp build_post_and_thread_mapping(post) do
    {:ok, thread} = build_thread_model([post.thread_id])

    content = %{
      "title" => post.title,
      "body" => post.body
    }

    post =
      post
      |> Map.put(:thread, thread)
      |> Map.delete(:thread_id)
      |> Map.put(:content, content)
      |> Map.delete(:title)
      |> Map.delete(:body)

    post
  end

  defp build_board_mapping(category, board) do
    [
      %{
        id: category.id,
        name: category.name,
        type: "category",
        view_order: category.view_order
      },
      %{
        id: board.id,
        name: board.name,
        type: "board",
        category_id: category.id,
        view_order: category.view_order + 1
      }
    ]
  end

  defp return_tuple(object) do
    if length(object) > 1 do
      {:ok, object}
    else
      {:ok, List.first(object)}
    end
  end

  defp get_post(id) do
    from(m in "smf_messages",
      limit: 1,
      where: m.id_msg == ^id,
      select: %{
        id: m.id_msg,
        thread_id: m.id_topic,
        board_id: m.id_board,
        user_id: m.id_member,
        title: m.subject,
        body: m.body,
        username: m.posterName,
        user_email: m.posterEmail,
        created_at: m.posterTime,
        modified_time: m.modifiedTime,
        avatar: m.icon
      }
    )
    |> SmfRepo.one()
    |> case do
      nil ->
        {:error, "Posts not found for id: #{id}"}

      post ->
        post
    end
  end
end
