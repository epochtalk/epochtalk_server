defmodule Test.Support.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Test.Support.ConnCase, async: true`, although
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

  # private username/email/password from user seed in `mix test` (see mix.exs)
  @test_private_username "private"
  @test_private_email "private@test.com"
  @test_private_password "password"
  @test_private_user_attrs %{
    username: @test_private_username,
    email: @test_private_email,
    password: @test_private_password
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
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Test.Support.ConnCase

      alias EpochtalkServerWeb.Router.Helpers, as: Routes

      use EpochtalkServerWeb, :verified_routes

      # The default endpoint for testing
      @endpoint EpochtalkServerWeb.Endpoint
    end
  end

  setup context do
    alias EpochtalkServer.Session
    alias EpochtalkServer.Models.User
    alias EpochtalkServer.Models.Ban
    import Test.Support.Factory

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(EpochtalkServer.Repo)

    unless context[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(EpochtalkServer.Repo, {:shared, self()})
    end

    {:ok, no_login_user} = User.by_username(@test_no_login_username)
    {:ok, private_user} = User.by_username(@test_private_username)
    {:ok, user} = User.by_username(@test_username)
    {:ok, admin_user} = User.by_username(@test_admin_username)
    {:ok, super_admin_user} = User.by_username(@test_super_admin_username)
    conn = Phoenix.ConnTest.build_conn()

    context_updates =
      {:ok,
       [
         users: %{
           no_login_user: no_login_user,
           private_user: private_user,
           user: user,
           admin_user: admin_user,
           super_admin_user: super_admin_user
         },
         user_attrs: %{
           no_login_user: @test_no_login_user_attrs,
           private_user: @test_private_user_attrs,
           user: @test_user_attrs,
           admin_user: @test_admin_user_attrs,
           super_admin_user: @test_super_admin_user_attrs
         }
       ]}

    # log user in if necessary
    context_updates =
      case context[:authenticated] do
        true ->
          remember_me = false
          {:ok, user, token, authed_conn} = Session.create(user, remember_me, conn)

          {:ok, k_list} = context_updates
          k_list = [conn: authed_conn] ++ k_list
          k_list = [authed_user: user] ++ k_list
          k_list = [token: token] ++ k_list
          k_list = [authed_user_attrs: @test_user_attrs] ++ k_list
          {:ok, k_list}

        :private ->
          remember_me = false
          {:ok, private_user, token, authed_conn} = Session.create(private_user, remember_me, conn)

          {:ok, k_list} = context_updates
          k_list = [conn: authed_conn] ++ k_list
          k_list = [authed_user: private_user] ++ k_list
          k_list = [token: token] ++ k_list
          k_list = [authed_user_attrs: @test_private_user_attrs] ++ k_list
          {:ok, k_list}

        :admin ->
          remember_me = false
          {:ok, admin_user, token, authed_conn} = Session.create(admin_user, remember_me, conn)

          {:ok, k_list} = context_updates
          k_list = [conn: authed_conn] ++ k_list
          k_list = [authed_user: admin_user] ++ k_list
          k_list = [token: token] ++ k_list
          k_list = [authed_user_attrs: @test_admin_user_attrs] ++ k_list
          {:ok, k_list}

        :super_admin ->
          remember_me = false

          {:ok, super_admin_user, token, authed_conn} =
            Session.create(super_admin_user, remember_me, conn)

          {:ok, k_list} = context_updates
          k_list = [conn: authed_conn] ++ k_list
          k_list = [authed_user: super_admin_user] ++ k_list
          k_list = [token: token] ++ k_list
          k_list = [authed_user_attrs: @test_super_admin_user_attrs] ++ k_list
          {:ok, k_list}

        # :authenticated not set, return default conn
        _ ->
          {:ok, k_list} = context_updates
          k_list = [conn: conn] ++ k_list
          {:ok, k_list}
      end

    # ban user if necessary
    context_updates =
      if context[:banned] do
        {:ok, banned_user_changeset} = Ban.ban(user)
        # update ban info in session
        Session.update(user.id)
        {:ok, k_list} = context_updates
        {:ok, [banned_user_changeset: banned_user_changeset] ++ k_list}
      else
        context_updates
      end

    # handle malicious score if necessary
    context_updates =
      if context[:malicious] do
        build(:banned_address, ip: "127.0.0.1", weight: 1.0)
        build(:banned_address, hostname: "localhost", weight: 1.0)

        # returns changeset from Ban.ban()
        {:ok, malicious_user_changeset} = User.handle_malicious_user(user, conn.remote_ip)
        {:ok, k_list} = context_updates
        {:ok, [malicious_user_changeset: malicious_user_changeset] ++ k_list}
      else
        context_updates
      end

    context_updates
  end
end
