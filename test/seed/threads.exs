alias EpochtalkServer.Models.Thread
alias EpochtalkServer.Repo

threads = [
  %{
    "title" => "test",
    "body" => "testing thread",
    "board_id" => 1,
    "sticky" => false,
    "locked" => false,
    "moderated" => false,
    "addPoll" => false,
    "pollValid" => false,
    "slug" => "test_slug"
  },
  %{
    "title" => "test2",
    "body" => "testing thread2",
    "board_id" => 1,
    "sticky" => false,
    "locked" => false,
    "moderated" => false,
    "addPoll" => false,
    "pollValid" => false,
    "slug" => "test_slug2"
  },
  %{
    "title" => "test3",
    "body" => "testing thread3",
    "board_id" => 1,
    "sticky" => false,
    "locked" => false,
    "moderated" => false,
    "addPoll" => false,
    "pollValid" => false,
    "slug" => "test_slug3"
  }
]

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

super_admin_board_thread = %{
  "title" => "super admin board thread test",
  "body" => "testing super admin board thread",
  "board_id" => 3,
  "sticky" => false,
  "locked" => false,
  "moderated" => false,
  "addPoll" => false,
  "pollValid" => false,
  "slug" => "super_admin_board_test_slug"
}

Repo.transaction(fn ->
  threads
  |> Enum.each(fn thread ->
    Thread.create(thread, 1)
    |> case do
      {:ok, _} ->
        IO.puts("Successfully seeded test thread")

      {:error, error} ->
        IO.puts("Error seeding test thread")
        IO.inspect(error)
    end
  end)
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

Repo.transaction(fn ->
  Thread.create(super_admin_board_thread, 1)
  |> case do
    {:ok, _} ->
      IO.puts("Successfully seeded super admin board test thread")

    {:error, error} ->
      IO.puts("Error seeding super admin board test thread")
      IO.inspect(error)
  end
end)
