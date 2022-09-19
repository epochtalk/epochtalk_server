alias EpochtalkServer.Models.User
System.argv()
|> case do
  [username, email, password, "admin" = _admin] ->
    admin = true
    User.create_user(%{username: username, email: email, password: password}, admin)
  [username, email, password] ->
    User.create_user(%{username: username, email: email, password: password})
  _ ->
    IO.puts("Usage: mix seed.user <username> <email> <password> [admin]")
    {:error, "Invalid arguments"}
end
|> case do
  {:ok, _} -> IO.puts("Successfully seeded user")
  {:error, error} ->
    IO.puts("Error seeding user")
    IO.inspect(error)
end
