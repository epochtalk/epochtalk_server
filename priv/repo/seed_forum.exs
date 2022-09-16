alias EpochtalkServer.Models.Category
alias EpochtalkServer.Models.Board
alias EpochtalkServer.Models.BoardMapping

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

category_id = Category.create(category).id

board_id = Board.create(board)
|> case do
  {:error, m} ->
    IO.puts("Seed failed")
    IO.inspect(m)
    Process.exit(self, :normal)
  b -> b.id
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
