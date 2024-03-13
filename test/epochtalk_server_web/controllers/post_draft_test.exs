defmodule Test.EpochtalkServerWeb.Controllers.PostDraft do
  use Test.Support.ConnCase, async: true
  import Test.Support.Factory

  setup %{users: %{admin_user: admin_user}} do
    draft_data =
      build(:post_draft, %{
        user_id: admin_user.id,
        draft: "draft test"
      })

    {:ok, draft_data: draft_data}
  end

  describe "by_user_id/1" do
    test "when unauthenticated, returns Unauthorized error", %{conn: conn} do
      response =
        conn
        |> get(Routes.post_draft_path(conn, :by_user_id))
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Not logged in, cannot get post draft"
    end

    @tag :authenticated
    test "when authenticated with no existing post draft, returns empty post draft",
         %{conn: conn, users: %{user: user}} do
      response =
        conn
        |> get(Routes.post_draft_path(conn, :by_user_id))
        |> json_response(200)

      assert response["user_id"] == user.id
      assert response["draft"] == nil
      assert response["updated_at"] == nil
    end

    @tag authenticated: :admin
    test "when authenticated with an existing post draft, returns existing post draft",
         %{conn: conn, users: %{admin_user: admin_user}, draft_data: draft_data} do
      response =
        conn
        |> get(Routes.post_draft_path(conn, :by_user_id))
        |> json_response(200)

      assert response["user_id"] == admin_user.id
      assert response["draft"] == draft_data.draft
      assert response["updated_at"] != nil
    end
  end

  describe "upsert/1" do
    test "when unauthenticated, returns Unauthorized error", %{conn: conn} do
      response =
        conn
        |> put(Routes.post_draft_path(conn, :upsert), %{"draft" => "Hello World"})
        |> json_response(400)

      assert response["error"] == "Bad Request"
      assert response["message"] == "Not logged in, cannot upsert post draft"
    end

    @tag :authenticated
    test "when authenticated with no existing post draft, creates and returns new post draft",
         %{conn: conn, users: %{user: user}} do
      response =
        conn
        |> put(Routes.post_draft_path(conn, :upsert), %{"draft" => "Hello World"})
        |> json_response(200)

      assert response["user_id"] == user.id
      assert response["draft"] == "Hello World"
      assert response["updated_at"] != nil
    end

    @tag authenticated: :admin
    test "when authenticated with an existing post draft, overrides existing and reutnrs new post draft",
         %{conn: conn, users: %{admin_user: admin_user}, draft_data: draft_data} do
      response =
        conn
        |> put(Routes.post_draft_path(conn, :upsert), %{"draft" => "Hello World"})
        |> json_response(200)

      assert response["user_id"] == admin_user.id
      assert response["draft"] != draft_data.draft
      assert response["draft"] == "Hello World"
      assert response["updated_at"] != nil
    end
  end
end
