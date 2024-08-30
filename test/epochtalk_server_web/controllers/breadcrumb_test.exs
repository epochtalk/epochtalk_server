defmodule Test.EpochtalkServerWeb.Controllers.Breadcrumb do
  use Test.Support.ConnCase, async: true
  import Test.Support.Factory

  setup %{users: %{user: user}} do
    category = insert(:category)
    parent_board = insert(:board)
    child_board = insert(:board)
    board_no_parent = insert(:board)

    build(:board_mapping,
      attributes: [
        [category: category, view_order: 0],
        [board: parent_board, category: category, view_order: 1],
        [board: child_board, parent: parent_board, view_order: 2],
        [board: board_no_parent, category: category, view_order: 3]
      ]
    )

    thread = build(:thread, board: child_board, user: user)
    thread_no_parent = build(:thread, board: board_no_parent, user: user)

    {
      :ok,
      category: category,
      parent_board: parent_board,
      child_board: child_board,
      thread: thread,
      board_no_parent: board_no_parent,
      thread_no_parent: thread_no_parent
    }
  end

  describe "breadcrumbs/2" do
    test "given a category id, returns breadcrumbs data for that category", %{
      conn: conn,
      category: category
    } do
      response =
        conn
        |> get(
          ~p"/api/breadcrumbs?#{%{
            "id" => category.id,
            "type" => "category"
          }}"
        )
        |> json_response(200)

      assert Enum.count(response["breadcrumbs"]) == 1

      response_category_crumb = response["breadcrumbs"] |> Enum.at(0)
      assert response_category_crumb["label"] == category.name

      assert response_category_crumb["opts"]["#"] ==
               "#{String.replace(String.downcase(category.name), " ", "-")}-0"

      assert response_category_crumb["routeName"] == "Boards"
    end

    test "given a board slug for a parent board, returns breadcrumbs data for that parent board and category",
         %{conn: conn, category: category, parent_board: parent_board} do
      response =
        conn
        |> get(
          ~p"/api/breadcrumbs?#{%{
            "id" => parent_board.slug,
            "type" => "parent"
          }}"
        )
        |> json_response(200)

      assert Enum.count(response["breadcrumbs"]) == 2

      response_category_crumb = response["breadcrumbs"] |> Enum.at(0)
      assert response_category_crumb["label"] == category.name

      assert response_category_crumb["opts"]["#"] ==
               "#{String.replace(String.downcase(category.name), " ", "-")}-0"

      assert response_category_crumb["routeName"] == "Boards"

      response_parent_crumb = response["breadcrumbs"] |> Enum.at(1)
      assert response_parent_crumb["label"] == parent_board.name
      assert response_parent_crumb["opts"]["boardSlug"] == parent_board.slug
      assert response_parent_crumb["routeName"] == "Threads"
    end

    test "given a board slug for a board with a parent, returns breadcrumbs data for that board, parent and category",
         %{conn: conn, category: category, parent_board: parent_board, child_board: child_board} do
      response =
        conn
        |> get(
          ~p"/api/breadcrumbs?#{%{
            "id" => child_board.slug,
            "type" => "board"
          }}"
        )
        |> json_response(200)

      assert Enum.count(response["breadcrumbs"]) == 3

      response_category_crumb = response["breadcrumbs"] |> Enum.at(0)
      assert response_category_crumb["label"] == category.name

      assert response_category_crumb["opts"]["#"] ==
               "#{String.replace(String.downcase(category.name), " ", "-")}-0"

      assert response_category_crumb["routeName"] == "Boards"

      response_parent_crumb = response["breadcrumbs"] |> Enum.at(1)
      assert response_parent_crumb["label"] == parent_board.name
      assert response_parent_crumb["opts"]["boardSlug"] == parent_board.slug
      assert response_parent_crumb["routeName"] == "Threads"

      response_board_crumb = response["breadcrumbs"] |> Enum.at(2)
      assert response_board_crumb["label"] == child_board.name
      assert response_board_crumb["opts"]["boardSlug"] == child_board.slug
      assert response_board_crumb["routeName"] == "Threads"
    end

    test "given a thread slug, returns breadcrumbs data for that thread, board, parent and category",
         %{
           conn: conn,
           category: category,
           parent_board: parent_board,
           child_board: child_board,
           thread: thread
         } do
      response =
        conn
        |> get(
          ~p"/api/breadcrumbs?#{%{
            "id" => thread.attributes["slug"],
            "type" => "thread"
          }}"
        )
        |> json_response(200)

      assert Enum.count(response["breadcrumbs"]) == 4

      response_category_crumb = response["breadcrumbs"] |> Enum.at(0)
      assert response_category_crumb["label"] == category.name

      assert response_category_crumb["opts"]["#"] ==
               "#{String.replace(String.downcase(category.name), " ", "-")}-0"

      assert response_category_crumb["routeName"] == "Boards"

      response_parent_crumb = response["breadcrumbs"] |> Enum.at(1)
      assert response_parent_crumb["label"] == parent_board.name
      assert response_parent_crumb["opts"]["boardSlug"] == parent_board.slug
      assert response_parent_crumb["routeName"] == "Threads"

      response_board_crumb = response["breadcrumbs"] |> Enum.at(2)
      assert response_board_crumb["label"] == child_board.name
      assert response_board_crumb["opts"]["boardSlug"] == child_board.slug
      assert response_board_crumb["routeName"] == "Threads"

      response_thread_crumb = response["breadcrumbs"] |> Enum.at(3)
      assert response_thread_crumb["label"] == thread.attributes["title"]
      assert response_thread_crumb["opts"]["locked"] == thread.attributes["locked"]
      assert response_thread_crumb["opts"]["slug"] == thread.attributes["slug"]
      assert response_thread_crumb["routeName"] == "Posts"
    end

    test "given a board slug for a board with no parent, returns breadcrumbs data for that board and category",
         %{conn: conn, category: category, board_no_parent: board_no_parent} do
      response =
        conn
        |> get(
          ~p"/api/breadcrumbs?#{%{
            "id" => board_no_parent.slug,
            "type" => "board"
          }}"
        )
        |> json_response(200)

      assert Enum.count(response["breadcrumbs"]) == 2

      response_category_crumb = response["breadcrumbs"] |> Enum.at(0)
      assert response_category_crumb["label"] == category.name

      assert response_category_crumb["opts"]["#"] ==
               "#{String.replace(String.downcase(category.name), " ", "-")}-0"

      assert response_category_crumb["routeName"] == "Boards"

      response_board_crumb = response["breadcrumbs"] |> Enum.at(1)
      assert response_board_crumb["label"] == board_no_parent.name
      assert response_board_crumb["opts"]["boardSlug"] == board_no_parent.slug
      assert response_board_crumb["routeName"] == "Threads"
    end

    test "given a thread slug for a board with no parent, returns breadcrumbs data for that thread, board and category",
         %{
           conn: conn,
           category: category,
           board_no_parent: board_no_parent,
           thread_no_parent: thread_no_parent
         } do
      response =
        conn
        |> get(
          ~p"/api/breadcrumbs?#{%{
            "id" => thread_no_parent.attributes["slug"],
            "type" => "thread"
          }}"
        )
        |> json_response(200)

      assert Enum.count(response["breadcrumbs"]) == 3

      response_category_crumb = response["breadcrumbs"] |> Enum.at(0)
      assert response_category_crumb["label"] == category.name

      assert response_category_crumb["opts"]["#"] ==
               "#{String.replace(String.downcase(category.name), " ", "-")}-0"

      assert response_category_crumb["routeName"] == "Boards"

      response_board_crumb = response["breadcrumbs"] |> Enum.at(1)
      assert response_board_crumb["label"] == board_no_parent.name
      assert response_board_crumb["opts"]["boardSlug"] == board_no_parent.slug
      assert response_board_crumb["routeName"] == "Threads"

      response_thread_crumb = response["breadcrumbs"] |> Enum.at(2)
      assert response_thread_crumb["label"] == thread_no_parent.attributes["title"]
      assert response_thread_crumb["opts"]["locked"] == thread_no_parent.attributes["locked"]
      assert response_thread_crumb["opts"]["slug"] == thread_no_parent.attributes["slug"]
      assert response_thread_crumb["routeName"] == "Posts"
    end

    test "given a category id for a category that does not exist, returns an empty list of breadcrumbs",
         %{conn: conn} do
      response =
        conn
        |> get(
          ~p"/api/breadcrumbs?#{%{
            "id" => 99,
            "type" => "category"
          }}"
        )
        |> json_response(200)

      assert Enum.empty?(response["breadcrumbs"]) == true
    end

    test "given a board slug for a board that does not exist, returns an empty list of breadcrumbs",
         %{conn: conn} do
      response =
        conn
        |> get(
          ~p"/api/breadcrumbs?#{%{
            "id" => "error_board",
            "type" => "board"
          }}"
        )
        |> json_response(200)

      assert Enum.empty?(response["breadcrumbs"]) == true
    end

    test "given a thread slug for a thread that does not exist, returns an empty list of breadcrumbs",
         %{conn: conn} do
      response =
        conn
        |> get(
          ~p"/api/breadcrumbs?#{%{
            "id" => "test_thread",
            "type" => "thread"
          }}"
        )
        |> json_response(200)

      assert Enum.empty?(response["breadcrumbs"]) == true
    end
  end
end
