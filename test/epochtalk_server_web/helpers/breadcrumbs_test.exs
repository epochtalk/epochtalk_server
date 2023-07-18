defmodule Test.EpochtalkServerWeb.Helpers.Breadcrumbs do
  use Test.Support.ConnCase, async: true

  describe "breadcrumbs/2" do
    test "given a category id, returns breadcrumbs data for that category", %{conn: conn} do
      conn =
        get(conn, Routes.breadcrumb_path(conn, :breadcrumbs, %{"id" => 1, "type" => "category"}))

      breadcrumbs = json_response(conn, 200)["breadcrumbs"]

      assert Enum.count(breadcrumbs) == 1

      category_crumb = breadcrumbs |> Enum.at(0)
      assert category_crumb["label"] == "General"
      assert category_crumb["opts"]["#"] == "general-0"
      assert category_crumb["routeName"] == "Boards"
    end

    test "given a board slug for a parent board, returns breadcrumbs data for that parent board and category",
         %{conn: conn} do
      conn =
        get(
          conn,
          Routes.breadcrumb_path(conn, :breadcrumbs, %{
            "id" => "parent-general-discussion",
            "type" => "parent"
          })
        )

      breadcrumbs = json_response(conn, 200)["breadcrumbs"]

      assert Enum.count(breadcrumbs) == 2

      category_crumb = breadcrumbs |> Enum.at(0)
      assert category_crumb["label"] == "General"
      assert category_crumb["opts"]["#"] == "general-0"
      assert category_crumb["routeName"] == "Boards"

      parent_crumb = breadcrumbs |> Enum.at(1)
      assert parent_crumb["label"] == "Parent General Discussion"
      assert parent_crumb["opts"]["boardSlug"] == "parent-general-discussion"
      assert parent_crumb["routeName"] == "Threads"
    end

    test "given a board slug for a board with a parent, returns breadcrumbs data for that board, parent and category",
         %{conn: conn} do
      conn =
        get(
          conn,
          Routes.breadcrumb_path(conn, :breadcrumbs, %{
            "id" => "general-discussion",
            "type" => "board"
          })
        )

      breadcrumbs = json_response(conn, 200)["breadcrumbs"]

      assert Enum.count(breadcrumbs) == 3

      category_crumb = breadcrumbs |> Enum.at(0)
      assert category_crumb["label"] == "General"
      assert category_crumb["opts"]["#"] == "general-0"
      assert category_crumb["routeName"] == "Boards"

      parent_crumb = breadcrumbs |> Enum.at(1)
      assert parent_crumb["label"] == "Parent General Discussion"
      assert parent_crumb["opts"]["boardSlug"] == "parent-general-discussion"
      assert parent_crumb["routeName"] == "Threads"

      board_crumb = breadcrumbs |> Enum.at(2)
      assert board_crumb["label"] == "General Discussion"
      assert board_crumb["opts"]["boardSlug"] == "general-discussion"
      assert board_crumb["routeName"] == "Threads"
    end

    test "given a thread slug, returns breadcrumbs data for that thread, board, parent and category",
         %{conn: conn} do
      conn =
        get(
          conn,
          Routes.breadcrumb_path(conn, :breadcrumbs, %{"id" => "test_slug", "type" => "thread"})
        )

      breadcrumbs = json_response(conn, 200)["breadcrumbs"]

      assert Enum.count(breadcrumbs) == 4

      category_crumb = breadcrumbs |> Enum.at(0)
      assert category_crumb["label"] == "General"
      assert category_crumb["opts"]["#"] == "general-0"
      assert category_crumb["routeName"] == "Boards"

      parent_crumb = breadcrumbs |> Enum.at(1)
      assert parent_crumb["label"] == "Parent General Discussion"
      assert parent_crumb["opts"]["boardSlug"] == "parent-general-discussion"
      assert parent_crumb["routeName"] == "Threads"

      board_crumb = breadcrumbs |> Enum.at(2)
      assert board_crumb["label"] == "General Discussion"
      assert board_crumb["opts"]["boardSlug"] == "general-discussion"
      assert board_crumb["routeName"] == "Threads"

      thread_crumb = breadcrumbs |> Enum.at(3)
      assert thread_crumb["label"] == "test"
      assert thread_crumb["opts"]["locked"] == false
      assert thread_crumb["opts"]["slug"] == "test_slug"
      assert thread_crumb["routeName"] == "Posts"
    end

    test "given a board slug for a board with no parent, returns breadcrumbs data for that board and category",
         %{conn: conn} do
      conn =
        get(
          conn,
          Routes.breadcrumb_path(conn, :breadcrumbs, %{"id" => "admin-board", "type" => "board"})
        )

      breadcrumbs = json_response(conn, 200)["breadcrumbs"]

      assert Enum.count(breadcrumbs) == 2

      category_crumb = breadcrumbs |> Enum.at(0)
      assert category_crumb["label"] == "General"
      assert category_crumb["opts"]["#"] == "general-0"
      assert category_crumb["routeName"] == "Boards"

      board_crumb = breadcrumbs |> Enum.at(1)
      assert board_crumb["label"] == "Admin Board"
      assert board_crumb["opts"]["boardSlug"] == "admin-board"
      assert board_crumb["routeName"] == "Threads"
    end

    test "given a category id for a category that does not exist, returns an empty list of breadcrumbs",
         %{conn: conn} do
      conn =
        get(conn, Routes.breadcrumb_path(conn, :breadcrumbs, %{"id" => 99, "type" => "category"}))

      breadcrumbs = json_response(conn, 200)["breadcrumbs"]
      assert Enum.empty?(breadcrumbs)
    end

    test "given a board slug for a board that does not exist, returns an empty list of breadcrumbs",
         %{conn: conn} do
      conn =
        get(
          conn,
          Routes.breadcrumb_path(conn, :breadcrumbs, %{"id" => "error_board", "type" => "board"})
        )

      breadcrumbs = json_response(conn, 200)["breadcrumbs"]
      assert Enum.empty?(breadcrumbs)
    end

    test "given a thread slug for a thread that does not exist, returns an empty list of breadcrumbs",
         %{conn: conn} do
      conn =
        get(
          conn,
          Routes.breadcrumb_path(conn, :breadcrumbs, %{"id" => "test-thread", "type" => "thread"})
        )

      breadcrumbs = json_response(conn, 200)["breadcrumbs"]
      assert Enum.empty?(breadcrumbs)
    end
  end
end
