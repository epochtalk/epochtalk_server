import Test.Support.Factory

test_super_admin_user_username = "superadmin"
test_super_admin_user_email = "superadmin@test.com"
test_super_admin_user_password = "password"

test_admin_user_username = "admin"
test_admin_user_email = "admin@test.com"
test_admin_user_password = "password"

test_user_username = "test"
test_user_email = "test@test.com"
test_user_password = "password"

build(:user,
  username: test_super_admin_user_username,
  email: test_super_admin_user_email,
  password: test_super_admin_user_password
)
|> with_role_id(1)

build(:user,
  username: test_admin_user_username,
  email: test_admin_user_email,
  password: test_admin_user_password
)
|> with_role_id(2)

build(:user,
  username: test_user_username,
  email: test_user_email,
  password: test_user_password
)

IO.puts("Successfully seeded test users")
