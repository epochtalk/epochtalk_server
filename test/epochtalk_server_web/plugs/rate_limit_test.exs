defmodule Test.EpochtalkServerWeb.Plugs.RateLimit do
  @moduledoc """
  This test sets async: false because checks rate limits,
  which may be succeptible to interference from other tests
  """
  use Test.Support.ConnCase, async: false
  alias EpochtalkServerWeb.CustomErrors.RateLimitExceeded

  setup %{conn: conn} do
    one_second_in_ms = 1000
    # reset 1 second rate limit timer
    :timer.sleep(one_second_in_ms)
    # enforce rate limit during these tests
    conn = conn
    |> Map.put(:enforce_rate_limit, true)
    {:ok, conn: conn}
  end

  describe "rate_limit_request/2" do
    test "when requesting GET, allows up to 10 requests per second", %{conn: conn} do
      1..15
      |> Enum.map(fn n ->
        if n > 10 do
          assert_raise RateLimitExceeded,
                      "GET rate limit exceeded (10)",
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
  end
end
