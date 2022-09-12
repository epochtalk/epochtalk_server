alias EpochtalkServer.Models.User
System.argv()
|> case do
  [username, email, password, "admin" = _admin] ->
    admin = true
    User.seed_user(username, email, password, admin)
  [username, email, password] ->
    User.seed_user(username, email, password)
end
|> case do
  {:ok, _} -> IO.puts("Successfully seeded user")
  {:error, _} -> IO.puts("Error seeding user")
