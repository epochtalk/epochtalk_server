alias EpochtalkServer.Models.User

test_user_username = "test"
test_user_email = "test@test.com"
test_user_password = "password"

test_admin_user_username = "admin"
test_admin_user_email = "admin@test.com"
test_admin_user_password = "password"
test_admin_user_admin = true

User.create(%{username: test_user_username, email: test_user_email, password: test_user_password})
|> case do
  {:ok, _} -> IO.puts("Successfully seeded test user")
  {:error, error} ->
    IO.puts("Error seeding test user")
    IO.inspect(error)
end

User.create(%{username: test_admin_user_username, email: test_admin_user_email, password: test_admin_user_password}, test_admin_user_admin)
|> case do
  {:ok, _} -> IO.puts("Successfully seeded test admin user")
  {:error, error} ->
    IO.puts("Error seeding test admin user")
    IO.inspect(error)
end
