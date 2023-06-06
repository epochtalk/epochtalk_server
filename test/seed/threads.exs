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

admin_board_thread = %{
  "title" => "admin board thread test",
  "body" => "testing admin board thread",
  "board_id" => 2,
  "sticky" => false,
  "locked" => false,
  "moderated" => false,
  "addPoll" => false,
  "pollValid" => false,
  "slug" => "admin_board_test_slug"
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
  Thread.create(admin_board_thread, 1)
  |> case do
    {:ok, _} ->
      IO.puts("Successfully seeded admin board test thread")

    {:error, error} ->
      IO.puts("Error seeding admin board test thread")
      IO.inspect(error)
  end
end)
