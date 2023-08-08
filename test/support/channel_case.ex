defmodule Test.Support.ChannelCase do
  @moduledoc """
  This module defines the test case to be used by
  channel tests.

  Such tests rely on `Phoenix.ChannelTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Test.Support.ChannelCase, async: true`, although
  this option is not recommended for other databases.
  """

  # username from user seed in `mix test` (see mix.exs)
  @test_username "user"

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with channels
      import Phoenix.ChannelTest
      import Test.Support.ChannelCase

      # The default endpoint for testing
      @endpoint EpochtalkServerWeb.Endpoint
    end
  end

  @endpoint EpochtalkServerWeb.Endpoint
  setup context do
    Test.Support.DataCase.setup_sandbox(context)
    import Phoenix.ChannelTest
    alias EpochtalkServer.Session
    alias EpochtalkServer.Models.User
    alias EpochtalkServerWeb.UserSocket
    alias EpochtalkServerWeb.UserChannel

    {:ok, user} = User.by_username(@test_username)
    conn = Phoenix.ConnTest.build_conn()

    if context[:authenticated] do
      # create session and socket
      {:ok, authed_user, token, _conn} = Session.create(user, false, conn)
      user_id = authed_user.id

      socket =
        UserSocket
        |> socket("user:#{user_id}", %{guardian_default_token: token, user_id: user_id})

      # determine which channel to join
      channel =
        case context[:authenticated] do
          true -> nil
          "user:<user_id>" -> "user:#{user_id}"
          channel -> channel
        end

      socket =
        if channel do
          {:ok, _payload, socket} = socket |> subscribe_and_join(UserChannel, channel)
          socket
        end

      {:ok, socket: socket, user_id: user_id, token: token}
    else
      :ok
    end
  end
end
