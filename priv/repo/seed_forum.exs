alias EpochtalkServer.Models.Category
alias EpochtalkServer.Models.Board
alias EpochtalkServer.Models.BoardMapping
alias EpochtalkServer.Repo

category_name = "General"
category = %{
  name: category_name
}

board_name = "General Discussion"
board_description = "Every forum's got one; talk about anything here"
board_slug = "general-discussion"
board = %{
  name: board_name,
  description: board_description,
  slug: board_slug
}

Repo.transaction(fn ->
  category_id = Category.create(category).id

  board_id = Board.create(board)
  |> case do
    {:ok, b} -> b.id
  end

  board_mapping = [
    %{
      id: category_id,
      name: category_name,
      type: "category",
      view_order: 0
    },
    %{
      id: board_id,
      name: board_name,
      type: "board",
      category_id: category_id,
      view_order: 1
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
