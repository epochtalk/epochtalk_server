defmodule Test.EpochtalkServerWeb.Controllers.Post do
  use Test.Support.ConnCase, async: true
  alias EpochtalkServerWeb.CustomErrors.InvalidPayload

  describe "preview/1" do
    test "when unauthenticated, returns Unauthorized error", %{conn: conn} do
      response =
        conn
        |> post(~p"/api/preview", %{"body" => "**Test**"})
        |> json_response(401)

      assert response["error"] == "Unauthorized"
      assert response["message"] == "No resource found"
    end

    @tag :authenticated
    test "when authenticated and supplied with markdown string for body, returns html string",
         %{conn: conn} do
      response =
        conn
        |> post(~p"/api/preview", %{"body" => "**Test**"})
        |> json_response(200)

      assert response["parsed_body"] == "<p>\n<strong>Test</strong></p>\n"
    end

    @tag :authenticated
    test "when authenticated and supplied with empty string for body, returns error",
         %{conn: conn} do
      assert_raise InvalidPayload,
                   ~r/^Invalid payload, key 'body' should be of type 'string' with length between 1 and 10000/,
                   fn ->
                     post(conn, ~p"/api/preview", %{"body" => ""})
                   end
    end

    @tag :authenticated
    test "when authenticated and supplied with too large of a string for body, returns error",
         %{conn: conn} do
      assert_raise InvalidPayload,
                   ~r/^Invalid payload, key 'body' should be of type 'string' with length between 1 and 10000/,
                   fn ->
                     post(conn, ~p"/api/preview", %{
                       "body" =>
                         for(_ <- 1..10_001, into: "", do: <<Enum.random('0123456789abcdef')>>)
                     })
                   end
    end
  end
end
