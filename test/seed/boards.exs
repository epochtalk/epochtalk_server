alias EpochtalkServer.Models.Category
alias EpochtalkServer.Models.Board
alias EpochtalkServer.Models.BoardMapping
alias EpochtalkServer.Repo

general_category = %{
  name: "General"
}

general_board = %{
  name: "General Discussion",
  description: "Every forum's got one; talk about anything here",
  slug: "general-discussion"
}

private_board = %{
  name: "Private Board",
  description: "this board is private",
  slug: "private-board"
}

Repo.transaction(fn ->
  general_category_id = Category.create(general_category)
  |> case do {:ok, c} -> c.id end

  general_board_id = Board.create(general_board)
  |> case do {:ok, b} -> b.id end

  private_board_id = Board.create(private_board)
  |> case do {:ok, b} -> b.id end

  board_mapping = [
    %{
      id: general_category_id,
      name: general_category.name,
      type: "category",
      view_order: 0
    },
    %{
      id: general_board_id,
      name: general_board.name,
      type: "board",
      category_id: general_category_id,
      view_order: 1
    },
    %{
      id: private_board_id,
      name: private_board.name,
      type: "board",
      category_id: general_category_id,
      viewable_by: 1,
      view_order: 2
    }
  ]

  BoardMapping.update(board_mapping)
end)
|> case do
  {:ok, _} -> IO.puts("Success")
  {:error, error} ->
    IO.puts("Error during seed")
    IO.inspect(error)
end
