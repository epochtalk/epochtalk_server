alias EpochtalkServer.Models.ModerationLog

log1 = %{mod: %{username: "mod",
           id: 1,
           ip: "127.0.0.1"},
    action: %{api_url: "/api/boards/all",
              api_method: "post",
              type: "adminBoards.updateCategories",
              display_text: "updated boards and categories",
              display_url: "admin-management.boards"},
    action_obj: %{}}
log2 = %{mod: %{username: "test",
           id: 2,
           ip: "127.0.0.1"},
    action: %{api_url: "/api/admin/moderators",
              api_method: "post",
              type: "adminModerators.add",
              display_text: "added user(s) \"test\" to list of moderators for board \"name\"",
              display_url: "threads.data({ boardSlug: 'name' })"},
    action_obj: %{}}

try do
  ModerationLog.create(log1)
    |> case do
      {:ok, _} -> IO.puts("Successfully Seeded Moderation Log Entry 1")
      {:error, error} ->
        IO.puts("Error Seeding Moderation Log Entry 1")
        IO.inspect(error)
    end
  ModerationLog.create(log2)
    |> case do
      {:ok, _} -> IO.puts("Successfully Seeded Moderation Log Entry 2")
      {:error, error} ->
        IO.puts("Error Seeding Moderation Log Entry 2")
        IO.inspect(error)
    end
rescue
  Postgrex.Error -> IO.puts("Error seeding Moderation Log. Moderation Log may already be seeded.")
end

