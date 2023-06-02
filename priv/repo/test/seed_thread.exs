alias EpochtalkServer.Models.Thread
alias EpochtalkServer.Repo

thread = %{
  "title" => "test",
  "body" => "testing thread",
  "board_id" => 1,
  "sticky" => false,
  "locked" => false,
  "moderated" => false,
  "addPoll" => false,
  "pollValid" => false,
  "slug" => "test_slug"
}

Repo.transaction(fn ->
  Thread.create(thread, 1)
  |> case do
    {:ok, _} ->
      IO.puts("Successfully seeded test thread")

    {:error, error} ->
      IO.puts("Error seeding test thread")
      IO.inspect(error)
  end
end)
