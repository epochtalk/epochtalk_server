defmodule Test.EpochtalkServerWeb.Plugs.RateLimit do
  @moduledoc """
  This test sets async: false because checks rate limits,
  which may be succeptible to interference from other tests
  """
  use Test.Support.ConnCase, async: false
  alias EpochtalkServerWeb.CustomErrors.RateLimitExceeded

  @one_second_in_ms 1000

  setup %{conn: conn} do
    # enforce rate limit during these tests
    conn =
      conn
      |> Map.put(:enforce_rate_limit, true)

    {:ok, conn: conn}
  end

  describe "rate_limit_request/2" do
    # synchronously delay 1 second to reset rate limit timers
    :timer.sleep(@one_second_in_ms)

    test "when requesting GET, allows up to max requests per second", %{conn: conn} do
      # load rate limits
      {_, max_get_per_second} =
        Application.get_env(:epochtalk_server, EpochtalkServer.RateLimiter)
        |> Keyword.get(:get)

      1..(max_get_per_second + 5)
      |> Enum.map(fn n ->
        # test request rate limit
        if n > max_get_per_second do
          assert_raise RateLimitExceeded,
                       "GET rate limit exceeded (#{max_get_per_second})",
                       fn ->
                         conn
                         |> get(Routes.board_path(conn, :by_category))
                       end
        else
          response =
            conn
            |> get(Routes.board_path(conn, :by_category))
            |> json_response(200)

          assert response |> Map.get("boards") == []
        end
      end)
    end

    test "when requesting POST, allows up to max requests per second", %{conn: conn} do
      # load rate limits
      {_, max_post_per_second} =
        Application.get_env(:epochtalk_server, EpochtalkServer.RateLimiter)
        |> Keyword.get(:post)

      1..(max_post_per_second + 5)
      |> Enum.map(fn n ->
        # test request rate limit
        if n > max_post_per_second do
          assert_raise RateLimitExceeded,
                       "POST rate limit exceeded (#{max_post_per_second})",
                       fn ->
                         conn
                         |> post(Routes.user_path(conn, :login, %{}))
                       end
        else
          response =
            conn
            |> post(Routes.user_path(conn, :login, %{username: "logintest", password: "1"}))
            |> json_response(400)
          assert response["error"] == "Bad Request"
          assert response["message"] == "Invalid credentials"
        end
      end)
    end

    @tag :authenticated
    test "when requesting PUT, allows up to max requests per second", %{conn: conn} do
      # load rate limits
      {_, max_put_per_second} =
        Application.get_env(:epochtalk_server, EpochtalkServer.RateLimiter)
        |> Keyword.get(:put)

      1..(max_put_per_second + 5)
      |> Enum.map(fn n ->
        # test request rate limit
        if n > max_put_per_second do
          assert_raise RateLimitExceeded,
                       "PUT rate limit exceeded (#{max_put_per_second})",
                       fn ->
                         conn
                         |> put(Routes.poll_path(conn, :update, -1), %{})
                       end
        else
          response =
            conn
            |> put(Routes.poll_path(conn, :update, -1), %{})
            |> json_response(400)
          assert response["error"] == "Bad Request"
          assert response["message"] == "Error, cannot edit poll"
        end
      end)
    end

    test "when requesting DELETE, allows up to max requests per second", %{conn: conn} do
      # load rate limits
      {_, max_delete_per_second} =
        Application.get_env(:epochtalk_server, EpochtalkServer.RateLimiter)
        |> Keyword.get(:delete)

      1..(max_delete_per_second + 5)
      |> Enum.map(fn n ->
        # test request rate limit
        if n > max_delete_per_second do
          assert_raise RateLimitExceeded,
                       "DELETE rate limit exceeded (#{max_delete_per_second})",
                       fn ->
                         conn
                         |> delete(Routes.user_path(conn, :logout))
                       end
        else
          response =
            conn
            |> delete(Routes.user_path(conn, :logout))
            |> json_response(400)
          assert response["error"] == "Bad Request"
          assert response["message"] == "Not logged in"
        end
      end)
    end
  end
end
