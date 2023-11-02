import Test.Support.Factory

test_super_admin_user_username = "superadmin"
test_super_admin_user_email = "superadmin@test.com"
test_super_admin_user_password = "password"

test_admin_user_username = "admin"
test_admin_user_email = "admin@test.com"
test_admin_user_password = "password"

test_global_mod_user_username = "globalmod"
test_global_mod_user_email = "globalmod@test.com"
test_global_mod_user_password = "password"

test_mod_user_username = "mod"
test_mod_user_email = "mod@test.com"
test_mod_user_password = "password"

test_user_username = "user"
test_user_email = "user@test.com"
test_user_password = "password"

test_patroller_user_username = "patroller"
test_patroller_user_email = "patroller@test.com"
test_patroller_user_password = "password"

test_newbie_user_username = "newbie"
test_newbie_user_email = "newbie@test.com"
test_newbie_user_password = "password"

test_banned_user_username = "banned"
test_banned_user_email = "banned@test.com"
test_banned_user_password = "password"

test_anonymous_user_username = "anonymous"
test_anonymous_user_email = "anonymous@test.com"
test_anonymous_user_password = "password"

test_private_user_username = "private"
test_private_user_email = "private@test.com"
test_private_user_password = "password"

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
  username: test_global_mod_user_username,
  email: test_global_mod_user_email,
  password: test_global_mod_user_password
)
|> with_role_id(3)

build(:user,
  username: test_mod_user_username,
  email: test_mod_user_email,
  password: test_mod_user_password
)
|> with_role_id(4)

build(:user,
  username: test_user_username,
  email: test_user_email,
  password: test_user_password
)

build(:user,
  username: test_patroller_user_username,
  email: test_patroller_user_email,
  password: test_patroller_user_password
)
|> with_role_id(6)

build(:user,
  username: test_newbie_user_username,
  email: test_newbie_user_email,
  password: test_newbie_user_password
)
|> with_role_id(7)

# TODO(akinsey): actually ban the user, this user only has banned role
build(:user,
  username: test_banned_user_username,
  email: test_banned_user_email,
  password: test_banned_user_password
)
|> with_role_id(8)

build(:user,
  username: test_anonymous_user_username,
  email: test_anonymous_user_email,
  password: test_anonymous_user_password
)
|> with_role_id(9)

build(:user,
  username: test_private_user_username,
  email: test_private_user_email,
  password: test_private_user_password
)
|> with_role_id(10)

IO.puts("Successfully seeded test users")
