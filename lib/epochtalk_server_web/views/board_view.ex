defmodule EpochtalkServerWeb.BoardView do
  use EpochtalkServerWeb, :view

  @moduledoc """
  Renders and formats `Board` data, in JSON format for frontend
  """

  @doc """
  Renders whatever data it is passed when template not found. Data pass through
  for rendering misc responses (ex: {found: true} or {success: true})
  ## Example
      iex> EpochtalkServerWeb.BoardView.render("DoesNotExist.json", data: %{anything: "abc"})
      %{anything: "abc"}
      iex> EpochtalkServerWeb.BoardView.render("DoesNotExist.json", data: %{success: true})
      %{success: true}
  """
  def template_not_found(_template, %{data: data}), do: data

  @doc """
  Renders `Board` data by `Category`.
  """
  def render("by_category.json", %{
        categories: categories,
        board_moderators: board_moderators,
        board_mapping: board_mapping,
        user_priority: user_priority
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
            user_priority
          )

        acc ++ [category]
      end)

    # return boards nested within categories
    %{boards: categories}
  end

  @doc """
  Renders `Board` for find query.
  """
  def render("find.json", %{
        board_moderators: board_moderators,
        board_mapping: board_mapping,
        board_id: board_id,
        user_priority: user_priority
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

    [board] = Enum.filter(board_mapping, fn bm -> bm.board_id == board_id end)

    # flatten needed boards data
    board =
      board
      |> Map.merge(board.board || %{})
      |> Map.merge(board.stats || %{})
      |> Map.merge(board.thread || %{})

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


  @doc """
  Board view helper method for mapping childboards to board using board mapping and user priority
  """
  def process_children_from_board_mapping(
         board_mapping_key,
         board_mapping,
         child_key,
         parent,
         user_priority
       ) do
    # look through board mapping, filter boards belonging to parent
    boards =
      Enum.filter(board_mapping, fn board -> Map.get(board, board_mapping_key) == parent.id end)

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
          |> Map.merge(board.board || %{})
          |> Map.merge(board.stats || %{})
          |> Map.merge(board.thread || %{})

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
            user_priority
          )

        acc ++ [board]
      end)

    # remove ecto struct and meta from category map
    parent =
      Map.put(parent, child_key, boards) |> Map.delete(:__meta__) |> Map.delete(:__struct__)

    # return parent with filtered children
    parent
  end
end
