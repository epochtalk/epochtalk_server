import Test.Support.Factory

test_super_admin_user_username = "superadmin"
test_super_admin_user_email = "superadmin@test.com"
test_super_admin_user_password = "password"

test_admin_user_username = "admin"
test_admin_user_email = "admin@test.com"
test_admin_user_password = "password"

test_user_username = "user"
test_user_email = "user@test.com"
test_user_password = "password"

test_private_user_username = "private"
test_private_user_email = "private@test.com"
test_private_user_password = "password"

test_no_login_user_username = "no_login"
test_no_login_user_email = "no_login@test.com"
test_no_login_user_password = "password"

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

build(:user,
  username: test_private_user_username,
  email: test_private_user_email,
  password: test_private_user_password
)
|> with_role_id(10)

build(:user,
  username: test_no_login_user_username,
  email: test_no_login_user_email,
  password: test_no_login_user_password
)

IO.puts("Successfully seeded test users")
