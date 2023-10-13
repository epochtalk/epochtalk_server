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

  # no_login username/email/password from user seed in `mix test` (see mix.exs)
  @test_no_login_username "no_login"
  @test_no_login_email "no_login@test.com"
  @test_no_login_password "password"
  @test_no_login_user_attrs %{
    username: @test_no_login_username,
    email: @test_no_login_email,
    password: @test_no_login_password
  }

  # username/email/password from user seed in `mix test` (see mix.exs)
  @test_username "user"
  @test_email "user@test.com"
  @test_password "password"
  @test_user_attrs %{
    username: @test_username,
    email: @test_email,
    password: @test_password
  }

  # admin username/email/password from user seed in `mix test` (see mix.exs)
  @test_admin_username "admin"
  @test_admin_email "admin@test.com"
  @test_admin_password "password"
  @test_admin_user_attrs %{
    username: @test_admin_username,
    email: @test_admin_email,
    password: @test_admin_password
  }

  # super admin username/email/password from user seed in `mix test` (see mix.exs)
  @test_super_admin_username "superadmin"
  @test_super_admin_email "superadmin@test.com"
  @test_super_admin_password "password"
  @test_super_admin_user_attrs %{
    username: @test_super_admin_username,
    email: @test_super_admin_email,
    password: @test_super_admin_password
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
    {:ok, no_login_user} = User.by_username(@test_no_login_username)
    {:ok, user} = User.by_username(@test_username)
    {:ok, admin_user} = User.by_username(@test_admin_username)
    {:ok, super_admin_user} = User.by_username(@test_super_admin_username)

    {
      :ok,
      [
        users: %{
          no_login_user: no_login_user,
          user: user,
          admin_user: admin_user,
          super_admin_user: super_admin_user
        },
        user_attrs: %{
          no_login_user: @test_no_login_user_attrs,
          user: @test_user_attrs,
          admin_user: @test_admin_user_attrs,
          super_admin_user: @test_super_admin_user_attrs
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
