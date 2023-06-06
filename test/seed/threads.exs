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

private_board_thread = %{
  "title" => "private thread test",
  "body" => "testing private thread",
  "board_id" => 2,
  "sticky" => false,
  "locked" => false,
  "moderated" => false,
  "addPoll" => false,
  "pollValid" => false,
  "slug" => "private_test_slug"
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

Repo.transaction(fn ->
  Thread.create(private_board_thread, 1)
  |> case do
    {:ok, _} ->
      IO.puts("Successfully seeded private test thread")

    {:error, error} ->
      IO.puts("Error seeding private test thread")
      IO.inspect(error)
  end
end)
