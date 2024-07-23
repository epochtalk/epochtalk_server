defmodule Test.EpochtalkServerWeb.Plugs.RateLimit do
  @moduledoc """
  This test sets async: false because checks rate limits,
  which may be succeptible to interference from other tests
  """
  use Test.Support.ConnCase, async: false

  setup %{conn: conn} do
    one_second_in_ms = 1000
    # reset 1 second rate limit timer
    :timer.sleep(one_second_in_ms)
    # enforce rate limit during these tests
    conn
    |> Map.put(:enforce_rate_limit, true)
    {:ok, conn: conn}
  end

  describe "rate_limit_request/2" do
    test "when requesting GET, allows 10 requests per second", %{conn: conn} do
      1..10
      |> Enum.map(fn _ ->
        response = conn
        |> get(Routes.board_path(conn, :by_category))
        |> json_response(200)
        assert response |> Map.get("boards") == []
      end)
    end
  end
end
