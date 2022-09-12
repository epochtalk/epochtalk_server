alias EpochtalkServer.Models.User
System.argv()
|> case do
  [username, email, password, "admin" = _admin] ->
    admin = true
    User.create_user(%{username: username, email: email, password: password}, admin)
  [username, email, password] ->
    User.create_user(%{username: username, email: email, password: password})
end
|> case do
  {:ok, _} -> IO.puts("Successfully seeded user")
  {:error, _} -> IO.puts("Error seeding user")
