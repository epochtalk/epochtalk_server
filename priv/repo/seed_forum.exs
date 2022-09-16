alias EpochtalkServer.Models.Category
category_name = "General"

Category.insert(%Category{name: category_name})
|> case do
  {:ok, category} ->
    IO.inspect(category)
  _ -> IO.puts("Seed failed, unable to create Category with name #{category_name}")
end
