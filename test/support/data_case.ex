defmodule Test.Support.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Test.Support.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  # super admin (1) username/email/password from user seed in `mix test` (see mix.exs)
  @test_super_admin_username "superadmin"
  @test_super_admin_email "superadmin@test.com"
  @test_super_admin_password "password"
  @test_super_admin_user_attrs %{
    username: @test_super_admin_username,
    email: @test_super_admin_email,
    password: @test_super_admin_password
  }

  # admin (2) username/email/password from user seed in `mix test` (see mix.exs)
  @test_admin_username "admin"
  @test_admin_email "admin@test.com"
  @test_admin_password "password"
  @test_admin_user_attrs %{
    username: @test_admin_username,
    email: @test_admin_email,
    password: @test_admin_password
  }

  # global mod (3) username/email/password from user seed in `mix test` (see mix.exs)
  @test_global_mod_username "globalmod"
  @test_global_mod_email "globalmod@test.com"
  @test_global_mod_password "password"
  @test_global_mod_user_attrs %{
    username: @test_global_mod_username,
    email: @test_global_mod_email,
    password: @test_global_mod_password
  }

  # mod (4) username/email/password from user seed in `mix test` (see mix.exs)
  @test_mod_username "mod"
  @test_mod_email "mod@test.com"
  @test_mod_password "password"
  @test_mod_user_attrs %{
    username: @test_mod_username,
    email: @test_mod_email,
    password: @test_mod_password
  }

  # user (5) username/email/password from user seed in `mix test` (see mix.exs)
  @test_username "user"
  @test_email "user@test.com"
  @test_password "password"
  @test_user_attrs %{
    username: @test_username,
    email: @test_email,
    password: @test_password
  }

  # patroller (6) username/email/password from user seed in `mix test` (see mix.exs)
  @test_patroller_username "patroller"
  @test_patroller_email "patroller@test.com"
  @test_patroller_password "password"
  @test_patroller_user_attrs %{
    username: @test_patroller_username,
    email: @test_patroller_email,
    password: @test_patroller_password
  }

  # newbie (7) username/email/password from user seed in `mix test` (see mix.exs)
  @test_newbie_username "newbie"
  @test_newbie_email "newbie@test.com"
  @test_newbie_password "password"
  @test_newbie_user_attrs %{
    username: @test_newbie_username,
    email: @test_newbie_email,
    password: @test_newbie_password
  }

  # banned (8) username/email/password from user seed in `mix test` (see mix.exs)
  @test_banned_username "banned"
  @test_banned_email "banned@test.com"
  @test_banned_password "password"
  @test_banned_user_attrs %{
    username: @test_banned_username,
    email: @test_banned_email,
    password: @test_banned_password
  }

  # anonymous (9) username/email/password from user seed in `mix test` (see mix.exs)
  @test_anonymous_username "anonymous"
  @test_anonymous_email "anonymous@test.com"
  @test_anonymous_password "password"
  @test_anonymous_user_attrs %{
    username: @test_anonymous_username,
    email: @test_anonymous_email,
    password: @test_anonymous_password
  }

  # private (10) username/email/password from user seed in `mix test` (see mix.exs)
  @test_private_username "private"
  @test_private_email "private@test.com"
  @test_private_password "password"
  @test_private_user_attrs %{
    username: @test_private_username,
    email: @test_private_email,
    password: @test_private_password
  }

  # no_login username/email/password from user seed in `mix test` (see mix.exs)
  @test_no_login_username "no_login"
  @test_no_login_email "no_login@test.com"
  @test_no_login_password "password"
  @test_no_login_user_attrs %{
    username: @test_no_login_username,
    email: @test_no_login_email,
    password: @test_no_login_password
  }

  use ExUnit.CaseTemplate

  using do
    quote do
      alias EpochtalkServer.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Test.Support.DataCase
    end
  end

  setup tags do
    alias EpochtalkServer.Models.User
    Test.Support.DataCase.setup_sandbox(tags)
    {:ok, super_admin_user} = User.by_username(@test_super_admin_username)
    {:ok, admin_user} = User.by_username(@test_admin_username)
    {:ok, global_mod_user} = User.by_username(@test_global_mod_username)
    {:ok, mod_user} = User.by_username(@test_mod_username)
    {:ok, user} = User.by_username(@test_username)
    {:ok, patroller_user} = User.by_username(@test_patroller_username)
    {:ok, newbie_user} = User.by_username(@test_newbie_username)
    {:ok, banned_user} = User.by_username(@test_banned_username)
    {:ok, anonymous_user} = User.by_username(@test_anonymous_username)
    {:ok, private_user} = User.by_username(@test_private_username)
    {:ok, no_login_user} = User.by_username(@test_no_login_username)

    {
      :ok,
      [
         users: %{
           super_admin_user: super_admin_user,
           admin_user: admin_user,
           global_mod_user: global_mod_user,
           mod_user: mod_user,
           user: user,
           patroller_user: patroller_user,
           newbie_user: newbie_user,
           banned_user: banned_user,
           anonymous_user: anonymous_user,
           private_user: private_user,
           no_login_user: no_login_user
         },
         user_attrs: %{
           super_admin_user: @test_super_admin_user_attrs,
           admin_user: @test_admin_user_attrs,
           global_mod_user: @test_global_mod_user_attrs,
           mod_user: @test_mod_user_attrs,
           user: @test_user_attrs,
           patroller_user: @test_patroller_user_attrs,
           newbie_user: @test_newbie_user_attrs,
           banned_user: @test_banned_user_attrs,
           anonymous_user: @test_anonymous_user_attrs,
           private_user: @test_private_user_attrs,
           no_login_user: @test_no_login_user_attrs
         }
      ]
    }
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(EpochtalkServer.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
