defmodule EpochtalkServerWeb.ErrorViewTest do
  use EpochtalkServerWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.json" do
    assert render(EpochtalkServerWeb.ErrorView, "404.json", []) == %{
      error: "Not Found",
      message: "Request Error",
      status: 404
    }
  end

  test "renders 500.json" do
    assert render(EpochtalkServerWeb.ErrorView, "500.json", []) == %{
      error: "Internal Server Error",
      message: "Request Error",
      status: 500
    }
  end
end
