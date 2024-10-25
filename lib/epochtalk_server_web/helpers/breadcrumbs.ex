defmodule EpochtalkServerWeb.Helpers.Breadcrumbs do
  @moduledoc """
  Helper for creating breadcrumbs
  """
  alias EpochtalkServerWeb.Helpers.ProxyConversion
  alias EpochtalkServer.Models.Category
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.Thread

  def build_crumbs(id, type, crumbs) when is_nil(id) and is_nil(type) do
    {:ok, crumbs}
  end

  def build_crumbs(id, type, crumbs) do
    case type do
      "category" ->
        build_category_crumbs(id, crumbs)

      "parent" ->
        build_board_crumbs(id, type, crumbs)

      "board" ->
        build_board_crumbs(id, type, crumbs)

      "thread" ->
        build_thread_crumbs(id, crumbs)

      _ ->
        build_crumbs(nil, nil, crumbs)
    end
  end

  defp build_category_crumbs(id, crumbs) do
    category =
      if is_binary(id),
        do: Category.find_by_id(String.to_integer(id)),
        else: Category.find_by_id(id)

    case category do
      {:ok, category} ->
        anchor =
          String.downcase(String.replace("#{category.name}-#{category.view_order}", ~r/\s+/, "-"))

        crumbs = [%{label: category.name, routeName: "Boards", opts: %{"#": anchor}} | crumbs]

        next_data = get_next_data(category, "category")
        build_crumbs(next_data[:id], next_data[:type], crumbs)

      {:error, :category_does_not_exist} ->
        build_crumbs(nil, nil, crumbs)
    end
  end

  defp build_board_crumbs(id, type, crumbs) do
    case Board.breadcrumb(id) do
      {:ok, board_breadcrumbs} ->
        board = Enum.at(board_breadcrumbs, 0)
        crumbs = [%{label: board.name, routeName: "Threads", opts: %{boardSlug: id}} | crumbs]

        next_data =
          if type == "parent",
            do: get_next_data(board, "parent"),
            else: get_next_data(board, "board")

        build_crumbs(next_data[:id], next_data[:type], crumbs)

      {:error, :board_does_not_exist} ->
        build_crumbs(nil, nil, crumbs)
    end
  end

  defp build_thread_crumbs(id, crumbs) do
    %{threads_seq: threads_seq} = Application.get_env(:epochtalk_server, :proxy_config)
    threads_seq = threads_seq |> String.to_integer()

    thread =
      cond do
        is_integer(id) && id < threads_seq ->
          ProxyConversion.build_model("thread", id)

        is_binary(id) ->
          Thread.find(id)

        true ->
          nil
      end

    if is_nil(thread) do
      build_crumbs(nil, nil, crumbs)
    else
      crumbs = [
        %{
          label: thread.title,
          routeName: "Posts",
          opts: %{slug: id, locked: thread.locked}
        }
        | crumbs
      ]

      next_data = get_next_data(thread, "thread")
      build_crumbs(next_data[:id], next_data[:type], crumbs)
    end
  end

  defp get_next_data(object, type) do
    case type do
      "category" ->
        %{id: nil, type: nil}

      "parent" ->
        %{id: object[:category_id], type: "category"}

      "board" ->
        if !object[:parent_slug] && object[:category_id] do
          %{id: object[:category_id], type: "category"}
        else
          %{id: object[:parent_slug], type: "parent"}
        end

      "thread" ->
        {:ok, board} = Board.find_by_id(object.board_id)
        %{id: board.slug, type: "board"}

      _ ->
        nil
    end
  end
end
