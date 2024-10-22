defmodule EpochtalkServerWeb.Controllers.BoardJSON do
  @moduledoc """
  Renders and formats `Controllers.Board` data, in JSON format for frontend
  """

  @doc """
  Renders `Board` id for slug to id route.
  """
  def slug_to_id(%{id: id}), do: %{id: id}

  @doc """
  Renders proxy version of `Board` data by `Category`.
  """
  def proxy_by_category(%{
        categories: categories,
        board_moderators: board_moderators,
        board_mapping: board_mapping,
        user_priority: user_priority,
        board_counts: board_counts,
        board_last_post_info: board_last_post_info
      }) do
    board_counts = map_to_id(board_counts)
    board_last_post_info = map_to_id(board_last_post_info)

    data =
      by_category(%{
        categories: categories,
        board_moderators: board_moderators,
        board_mapping: board_mapping,
        user_priority: user_priority,
        board_counts: board_counts,
        board_last_post_info: board_last_post_info
      })

    data
  end

  defp map_to_id(data), do: Enum.reduce(data, %{}, &(&2 |> Map.put(&1.id, Map.delete(&1, :id))))

  @doc """
  Renders `Board` data by `Category`.
  """
  def by_category(%{
        categories: categories,
        board_moderators: board_moderators,
        board_mapping: board_mapping,
        user_priority: user_priority,
        # board counts and last post info for proxy version
        board_counts: board_counts,
        board_last_post_info: board_last_post_info
      }) do
    # append board moderators to each board in board mapping
    board_mapping =
      Enum.map(board_mapping, fn board ->
        moderators =
          board_moderators
          |> Enum.filter(fn mod -> Map.get(mod, :board_id) == Map.get(board, :board_id) end)
          |> Enum.map(fn mod -> %{id: mod.user_id, username: mod.user.username} end)

        Map.put(board, :moderators, moderators)
      end)

    # filter out categories not matching user priority
    categories =
      Enum.filter(categories, fn cat ->
        view_priority = Map.get(cat, :viewable_by)
        is_nil(view_priority) || (!is_nil(view_priority) && user_priority <= view_priority)
      end)

    # iterate each category
    categories =
      Enum.reduce(categories, [], fn category, acc ->
        # look through board mapping, filter and process child boards for the current category
        category =
          process_children_from_board_mapping(
            :category_id,
            board_mapping,
            :boards,
            category,
            user_priority,
            # board counts and last post info for proxy version
            board_counts,
            board_last_post_info
          )

        acc ++ [category]
      end)

    # return boards nested within categories
    %{boards: categories}
  end

  @doc """
  Renders `Board` for find query.
  """
  def find(%{
        board_moderators: board_moderators,
        board_mapping: board_mapping,
        board_id: board_id,
        user_priority: user_priority
      }) do
    format_board_data_for_find(board_moderators, board_mapping, board_id, user_priority)
  end

  @doc """
  Renders `Board` data for movelist route
  """
  def movelist(%{movelist: movelist}), do: movelist

  @doc """
  Board view helper method for mapping childboards and other metadata to board using board mapping and user priority
  """
  def format_board_data_for_find(board_moderators, board_mapping, board_id, user_priority) do
    # filter out board by id
    [board] = Enum.filter(board_mapping, fn bm -> bm.board_id == board_id end)

    # append board moderators to board
    moderators =
      board_moderators
      |> Enum.filter(fn mod -> Map.get(mod, :board_id) == Map.get(board, :board_id) end)
      |> Enum.map(fn mod -> %{id: mod.user_id, username: mod.user.username} end)

    board = Map.put(board, :moderators, moderators)

    # flatten needed boards data
    board =
      board
      |> Map.merge(remove_nil(board.board))
      |> Map.merge(
        remove_nil(board.stats)
        |> Map.delete(:id)
      )
      |> Map.merge(board.thread)
      |> Map.merge(board.board.meta || board.stats)
      |> Map.delete(:meta)

    # delete unneeded properties
    board =
      board
      |> Map.delete(:board)
      |> Map.delete(:stats)
      |> Map.delete(:thread)
      |> Map.delete(:parent)
      |> Map.delete(:category)
      |> Map.delete(:__meta__)
      |> Map.delete(:__struct__)

    # handle deleted last post data
    if !!Map.get(board, :post_deleted) or !!Map.get(board, :user_deleted),
      do: board |> Map.put(:last_post_username, "deleted"),
      else: board

    # iterate each child board, attempt to map nested children from board mapping
    board =
      process_children_from_board_mapping(
        :parent_id,
        board_mapping,
        :children,
        board,
        user_priority
      )

    # return flattened board data with children, mod and last post data
    board
  end

  defp process_children_from_board_mapping(
         board_mapping_key,
         board_mapping,
         child_key,
         parent,
         user_priority,
         # board counts and last post info for proxy version
         board_counts \\ nil,
         board_last_post_info \\ nil
       ) do
    # get id of parent object could be board or category
    parent_id = if is_integer(Map.get(parent, :board_id)), do: parent.board_id, else: parent.id

    # look through board mapping, filter boards belonging to parent
    boards =
      Enum.filter(board_mapping, fn board -> Map.get(board, board_mapping_key) == parent_id end)

    # filter out boards not matching user priority
    boards =
      Enum.filter(boards, fn board ->
        view_priority = Map.get(board, :viewable_by)
        is_nil(view_priority) || (!is_nil(view_priority) && user_priority <= view_priority)
      end)

    # flatten preloaded board data onto board, remove struct and ecto meta
    boards =
      boards
      |> Enum.map(fn board ->
        # flatten needed boards data
        board =
          board
          |> Map.merge(remove_nil(board.board))
          |> Map.merge(remove_nil(board.stats))
          |> Map.merge(board.thread)

        # add board counts for proxy version
        board =
          if board_counts != nil,
            do: Map.merge(board, board_counts[board.id]),
            else: board

        # add board last post info for proxy version
        board =
          if board_last_post_info != nil,
            do: Map.merge(board, board_last_post_info[board.id]),
            else: board

        # delete unneeded properties
        board =
          board
          |> Map.delete(:board)
          |> Map.delete(:stats)
          |> Map.delete(:thread)
          |> Map.delete(:parent)
          |> Map.delete(:category)
          |> Map.delete(:__meta__)
          |> Map.delete(:__struct__)

        # handle deleted last post data
        if !!Map.get(board, :post_deleted) or !!Map.get(board, :user_deleted),
          do: board |> Map.put(:last_post_username, "deleted"),
          else: board
      end)

    # sort boards by view order within respective parent
    boards = boards |> Enum.sort_by(fn board -> board.view_order end)

    # iterate each child board, attempt to map nested children from board mapping
    boards =
      Enum.reduce(boards, [], fn board, acc ->
        board =
          process_children_from_board_mapping(
            :parent_id,
            board_mapping,
            :children,
            board,
            user_priority,
            board_counts,
            board_last_post_info
          )

        acc ++ [board]
      end)

    # remove ecto struct and meta from category map
    parent =
      Map.put(parent, child_key, boards) |> Map.delete(:__meta__) |> Map.delete(:__struct__)

    # return parent with filtered children
    parent
  end

  defp remove_nil(nil), do: %{}

  defp remove_nil(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> remove_nil()
  end

  defp remove_nil(map) when is_map(map) do
    map
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end
end
