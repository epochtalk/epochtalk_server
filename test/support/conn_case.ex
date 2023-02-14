defmodule EpochtalkServerWeb.ConnCase do
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
  by setting `use EpochtalkServerWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  # username/email/password from user seed in `mix test` (see mix.exs)
  @test_username "test"
  @test_email "test@test.com"
  @test_password "password"
  @test_user_attrs %{
    username: @test_username,
    email: @test_email,
    password: @test_password
  }

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import EpochtalkServerWeb.ConnCase

      alias EpochtalkServerWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint EpochtalkServerWeb.Endpoint
    end
  end

  setup tags do
    alias EpochtalkServer.Session
    alias EpochtalkServer.Models.User

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(EpochtalkServer.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(EpochtalkServer.Repo, {:shared, self()})
    end

    {:ok, user} = User.by_username(@test_username)

    if tags[:authenticated] do
      conn = Phoenix.ConnTest.build_conn()
      {:ok, user, token, conn} = Session.create(user, false, conn)
      {:ok, conn: conn, authed_user: user, token: token, authed_user_attrs: @test_user_attrs}
    else
      {:ok, conn: Phoenix.ConnTest.build_conn(), user: user, user_attrs: @test_user_attrs}
    end
  end
end
